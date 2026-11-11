import hashlib
import hmac
import json
import time

import httpx
import pytest

from app.db import Database
from app.models import PushEventInput, PushSubscriptionInput
from app.push_service import PushService
from app.webhook_security import UnsafeWebhookEndpointError, validate_webhook_endpoint


def make_service(database: Database, handler=None, *, allow_private: bool = False) -> PushService:
    transport = httpx.MockTransport(handler) if handler is not None else None
    return PushService(database, timeout_seconds=5, allow_private_webhooks=allow_private, transport=transport)


def subscribe_webhook(service: PushService, workspace: str = "a", endpoint: str = "https://example.com/hook"):
    service.subscribe(
        workspace, PushSubscriptionInput(id="hook-1", kind="webhook", endpoint=endpoint, secret="s3cret")
    )


def enqueue(service: PushService, workspace: str = "a"):
    return service.enqueue(workspace, PushEventInput(event_type="news.created", payload={"item_id": "n1"}))


def outbox_row(database: Database, event_id: str):
    with database.connection() as connection:
        return dict(connection.execute("SELECT * FROM push_outbox WHERE id=?", (event_id,)).fetchone())


async def test_dispatch_delivers_with_signature_and_idempotency_key(client):
    database = client.app.state.database
    received = []

    def handler(request: httpx.Request) -> httpx.Response:
        received.append(request)
        return httpx.Response(200)

    service = make_service(database, handler)
    subscribe_webhook(service)
    enqueue(service)
    pending = service.outbox("a", status="pending", limit=10)
    assert len(pending) == 1

    assert await service.dispatch_webhooks() == 1
    request = received[0]
    body = json.loads(request.content)
    assert body == {"item_id": "n1"}
    assert request.headers["X-GitHub-News-Event"] == "news.created"
    # Receivers need a stable dedup key for at-least-once redelivery.
    assert request.headers["X-GitHub-News-Event-Id"] == pending[0]["id"]
    expected = hmac.new(b"s3cret", request.content, hashlib.sha256).hexdigest()
    assert request.headers["X-GitHub-News-Signature"] == expected
    assert service.outbox("a", status="pending", limit=10) == []
    assert len(service.outbox("a", status="delivered", limit=10)) == 1


async def test_dispatch_failure_backs_off_then_dead_letters(client):
    database = client.app.state.database

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(500)

    service = make_service(database, handler)
    subscribe_webhook(service)
    enqueue(service)
    event_id = service.outbox("a", status="pending", limit=10)[0]["id"]

    assert await service.dispatch_webhooks() == 0
    row = outbox_row(database, event_id)
    assert row["status"] == "pending"
    assert row["attempts"] == 1
    assert row["next_attempt_at"] > int(time.time() * 1000)

    # Exhaust the retry budget directly; the row must become a queryable dead
    # letter instead of retrying a dead endpoint forever.
    with database.connection() as connection:
        connection.execute("UPDATE push_outbox SET attempts=11,next_attempt_at=0 WHERE id=?", (event_id,))
    assert await service.dispatch_webhooks() == 0
    row = outbox_row(database, event_id)
    assert row["status"] == "failed"
    assert row["attempts"] == 12
    assert service.outbox("a", status="failed", limit=10)[0]["id"] == event_id


async def test_ack_only_accepts_pending_rows(client):
    database = client.app.state.database
    service = make_service(database, lambda request: httpx.Response(200))
    subscribe_webhook(service)
    enqueue(service)
    event_id = service.outbox("a", status="pending", limit=10)[0]["id"]

    assert service.acknowledge("a", event_id) is True
    # Replayed acks must not rewrite a terminal state.
    assert service.acknowledge("a", event_id) is False
    assert service.acknowledge("other-workspace", event_id) is False


async def test_prune_removes_only_expired_terminal_rows(client):
    database = client.app.state.database
    service = make_service(database, lambda request: httpx.Response(200))
    subscribe_webhook(service)
    enqueue(service)
    event_id = service.outbox("a", status="pending", limit=10)[0]["id"]
    await service.dispatch_webhooks()

    now = int(time.time() * 1000)
    with database.connection() as connection:
        connection.execute(
            "UPDATE push_outbox SET delivered_at=? WHERE id=?", (now - 8 * 24 * 3600 * 1000, event_id)
        )
        connection.execute(
            "INSERT INTO push_outbox(id,workspace_id,subscription_id,event_type,payload_json,status,"
            "attempts,next_attempt_at,created_at) VALUES('old-failed','a','hook-1','t','{}','failed',12,?,0)",
            (now - 31 * 24 * 3600 * 1000,),
        )
        connection.execute(
            "INSERT INTO push_outbox(id,workspace_id,subscription_id,event_type,payload_json,status,"
            "attempts,next_attempt_at,created_at)"
            " VALUES('fresh-failed','a','hook-1','t','{}','failed',12,?,0)",
            (now - 1000,),
        )
    await service.dispatch_webhooks()
    with database.connection() as connection:
        remaining = {row[0] for row in connection.execute("SELECT id FROM push_outbox")}
    assert remaining == {"fresh-failed"}


@pytest.mark.parametrize(
    "endpoint",
    [
        "http://127.0.0.1/hook",
        "http://169.254.169.254/latest/meta-data/",
        "http://10.0.0.5/hook",
        "http://192.168.1.10/hook",
        "http://[::1]/hook",
        "file:///etc/passwd",
        "gopher://example.com/x",
        "https://user:pass@example.com/hook",
        "https:///missing-host",
    ],
)
def test_unsafe_webhook_endpoints_are_rejected(endpoint):
    with pytest.raises(UnsafeWebhookEndpointError):
        validate_webhook_endpoint(endpoint)


def test_public_webhook_endpoint_passes():
    # example.com resolves to public addresses; no network delivery happens.
    validate_webhook_endpoint("https://example.com/hook")


def test_private_webhooks_can_be_opted_in():
    validate_webhook_endpoint("http://127.0.0.1/hook", allow_private=True)


async def test_subscribe_rejects_unsafe_webhook_but_allows_lan_opt_in(client):
    database = client.app.state.database
    strict = make_service(database)
    with pytest.raises(UnsafeWebhookEndpointError):
        subscribe_webhook(strict, endpoint="http://127.0.0.1/hook")
    assert strict.outbox("a", status="pending", limit=10) == []

    relaxed = make_service(database, allow_private=True)
    subscribe_webhook(relaxed, endpoint="http://127.0.0.1/hook")


async def test_dispatch_revalidates_and_dead_letters_rebound_endpoint(client):
    database = client.app.state.database
    # Subscribe while private targets are allowed, then deliver with a strict
    # service: the delivery-time re-check must block without any HTTP call.
    relaxed = make_service(database, allow_private=True)
    subscribe_webhook(relaxed, endpoint="http://127.0.0.1/hook")
    enqueue(relaxed)
    event_id = relaxed.outbox("a", status="pending", limit=10)[0]["id"]

    calls = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request)
        return httpx.Response(200)

    strict = make_service(database, handler)
    assert await strict.dispatch_webhooks() == 0
    assert calls == []
    assert outbox_row(database, event_id)["status"] == "failed"


async def test_non_webhook_kinds_skip_url_validation(client):
    database = client.app.state.database
    service = make_service(database)
    # Gateway kinds carry device tokens, not URLs; they stay in the outbox for
    # an external gateway and must not be URL-validated.
    service.subscribe("a", PushSubscriptionInput(id="device-1", kind="fcm", endpoint="device-token"))
    assert service.enqueue("a", PushEventInput(event_type="t", payload={})) == 1
