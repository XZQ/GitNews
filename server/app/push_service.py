from __future__ import annotations

import asyncio
import hashlib
import hmac
import sqlite3
import time
import uuid

import httpx

from .db import Database, json_text, parse_json
from .models import PushEventInput, PushSubscriptionInput
from .webhook_security import UnsafeWebhookEndpointError, validate_webhook_endpoint

# Dead-letter after this many attempts instead of retrying dead endpoints forever.
_MAX_ATTEMPTS = 12
# Keep delivered rows 7 days for reconciliation and failed rows 30 days for
# operator inspection, then prune so the outbox cannot grow without bound.
_DELIVERED_RETENTION_MS = 7 * 24 * 3600 * 1000
_FAILED_RETENTION_MS = 30 * 24 * 3600 * 1000


class SubscriptionOwnershipError(Exception):
    """Raised when a subscription id already belongs to another workspace."""

    def __init__(self, subscription_id: str) -> None:
        super().__init__(f"subscription id already exists in another workspace: {subscription_id}")
        self.subscription_id = subscription_id


class PushService:
    def __init__(
        self,
        database: Database,
        timeout_seconds: float = 30,
        *,
        allow_private_webhooks: bool = False,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self.database = database
        self.timeout_seconds = timeout_seconds
        self.allow_private_webhooks = allow_private_webhooks
        # Injectable for tests; production uses the default network transport.
        self.transport = transport

    def subscribe(self, workspace_id: str, value: PushSubscriptionInput) -> dict[str, object]:
        if value.kind == "webhook":
            validate_webhook_endpoint(value.endpoint, allow_private=self.allow_private_webhooks)
        now = _now()
        with self.database.connection() as connection:
            # Subscription ids are client-supplied: scope the upsert to the
            # caller's workspace so an id collision from another workspace
            # cannot hijack the endpoint/secret of an existing subscription.
            connection.execute(
                """
                INSERT INTO push_subscriptions(id,workspace_id,kind,endpoint,secret,enabled,created_at)
                VALUES(?,?,?,?,?,1,?)
                ON CONFLICT(id) DO UPDATE SET
                  kind=excluded.kind, endpoint=excluded.endpoint,
                  secret=excluded.secret, enabled=1
                WHERE push_subscriptions.workspace_id=excluded.workspace_id
                """,
                (value.id, workspace_id, value.kind, value.endpoint, value.secret, now),
            )
            owner = connection.execute(
                "SELECT workspace_id FROM push_subscriptions WHERE id=?",
                (value.id,),
            ).fetchone()
        if owner is not None and owner["workspace_id"] != workspace_id:
            raise SubscriptionOwnershipError(value.id)
        return {"workspace_id": workspace_id, **value.model_dump(), "enabled": True, "created_at": now}

    def enqueue(self, workspace_id: str, event: PushEventInput) -> int:
        with self.database.connection() as connection:
            return self._enqueue_in_transaction(workspace_id, event, connection)

    def _enqueue_in_transaction(
        self, workspace_id: str, event: PushEventInput, connection: sqlite3.Connection
    ) -> int:
        now = _now()
        count = 0
        subscriptions = connection.execute(
            "SELECT id FROM push_subscriptions WHERE workspace_id=? AND enabled=1",
            (workspace_id,),
        ).fetchall()
        for subscription in subscriptions:
            connection.execute(
                """
                INSERT INTO push_outbox(
                  id,workspace_id,subscription_id,event_type,payload_json,status,
                  attempts,next_attempt_at,created_at
                ) VALUES(?,?,?,?,?,'pending',0,?,?)
                """,
                (
                    uuid.uuid4().hex,
                    workspace_id,
                    subscription["id"],
                    event.event_type,
                    json_text(event.payload),
                    now,
                    now,
                ),
            )
            count += 1
        return count

    def enqueue_all_workspaces(
        self, event: PushEventInput, *, connection: sqlite3.Connection | None = None
    ) -> int:
        """Reuse an ingestion transaction instead of opening nested SQLite writers."""
        if connection is None:
            with self.database.connection() as owned_connection:
                return self.enqueue_all_workspaces(event, connection=owned_connection)
        workspace_ids = [
            row["workspace_id"]
            for row in connection.execute(
                "SELECT DISTINCT workspace_id FROM push_subscriptions WHERE enabled=1"
            )
        ]
        return sum(
            self._enqueue_in_transaction(workspace_id, event, connection) for workspace_id in workspace_ids
        )

    def outbox(self, workspace_id: str, *, status: str, limit: int) -> list[dict[str, object]]:
        with self.database.connection() as connection:
            rows = connection.execute(
                """
                SELECT o.*,s.kind,s.endpoint FROM push_outbox o
                JOIN push_subscriptions s ON s.id=o.subscription_id
                WHERE o.workspace_id=? AND o.status=? ORDER BY o.created_at LIMIT ?
                """,
                (workspace_id, status, limit),
            ).fetchall()
        return [{**dict(row), "payload": parse_json(row["payload_json"])} for row in rows]

    def acknowledge(self, workspace_id: str, event_id: str) -> bool:
        with self.database.connection() as connection:
            # Only pending rows may be acknowledged; delivered/failed rows keep
            # their terminal state so a replayed ack cannot rewrite history.
            changed = connection.execute(
                """
                UPDATE push_outbox SET status='delivered',delivered_at=?
                WHERE id=? AND workspace_id=? AND status='pending'
                """,
                (_now(), event_id, workspace_id),
            ).rowcount
        return changed == 1

    async def dispatch_webhooks(self) -> int:
        now = _now()
        with self.database.connection() as connection:
            rows = connection.execute(
                """
                SELECT o.*,s.endpoint,s.secret FROM push_outbox o
                JOIN push_subscriptions s ON s.id=o.subscription_id
                WHERE o.status='pending' AND o.next_attempt_at<=? AND s.kind='webhook' AND s.enabled=1
                ORDER BY o.created_at LIMIT 100
                """,
                (now,),
            ).fetchall()
        delivered = 0
        async with httpx.AsyncClient(timeout=self.timeout_seconds, transport=self.transport) as client:
            for row in rows:
                # Re-validate at delivery time: DNS may have changed since
                # subscription (rebinding), and unsafe targets are dead-lettered
                # instead of retried. getaddrinfo blocks, so keep it off the loop.
                try:
                    await asyncio.to_thread(
                        validate_webhook_endpoint,
                        row["endpoint"],
                        allow_private=self.allow_private_webhooks,
                    )
                except UnsafeWebhookEndpointError:
                    self._mark_failed(row["id"])
                    continue
                body = row["payload_json"].encode()
                headers = {
                    "Content-Type": "application/json",
                    "X-GitHub-News-Event": row["event_type"],
                    # Stable outbox id so receivers can deduplicate at-least-once
                    # redeliveries (a crash after POST but before _mark).
                    "X-GitHub-News-Event-Id": row["id"],
                }
                if row["secret"]:
                    headers["X-GitHub-News-Signature"] = hmac.new(
                        row["secret"].encode(), body, hashlib.sha256
                    ).hexdigest()
                try:
                    response = await client.post(row["endpoint"], content=body, headers=headers)
                    response.raise_for_status()
                    self._mark(row["id"], delivered=True)
                    delivered += 1
                except Exception:  # noqa: BLE001 - retries are persisted
                    self._mark(row["id"], delivered=False, attempts=row["attempts"] + 1)
        self._prune()
        return delivered

    def _mark(self, event_id: str, *, delivered: bool, attempts: int = 0) -> None:
        with self.database.connection() as connection:
            if delivered:
                connection.execute(
                    "UPDATE push_outbox SET status='delivered',delivered_at=? WHERE id=?",
                    (_now(), event_id),
                )
            elif attempts >= _MAX_ATTEMPTS:
                connection.execute(
                    "UPDATE push_outbox SET status='failed',attempts=?,next_attempt_at=? WHERE id=?",
                    (attempts, _now(), event_id),
                )
            else:
                delay = min(3600, 30 * (2 ** min(attempts, 7))) * 1000
                connection.execute(
                    "UPDATE push_outbox SET attempts=?,next_attempt_at=? WHERE id=?",
                    (attempts, _now() + delay, event_id),
                )

    def _mark_failed(self, event_id: str) -> None:
        with self.database.connection() as connection:
            connection.execute(
                "UPDATE push_outbox SET status='failed',next_attempt_at=? WHERE id=?",
                (_now(), event_id),
            )

    def _prune(self) -> None:
        now = _now()
        with self.database.connection() as connection:
            connection.execute(
                "DELETE FROM push_outbox WHERE status='delivered' AND delivered_at<?",
                (now - _DELIVERED_RETENTION_MS,),
            )
            connection.execute(
                "DELETE FROM push_outbox WHERE status='failed' AND next_attempt_at<?",
                (now - _FAILED_RETENTION_MS,),
            )


def _now() -> int:
    return int(time.time() * 1000)
