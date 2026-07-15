from __future__ import annotations

import hashlib
import hmac
import time
import uuid

import httpx

from .db import Database, json_text, parse_json
from .models import PushEventInput, PushSubscriptionInput


class PushService:
    def __init__(self, database: Database, timeout_seconds: float = 30) -> None:
        self.database = database
        self.timeout_seconds = timeout_seconds

    def subscribe(self, workspace_id: str, value: PushSubscriptionInput) -> dict[str, object]:
        now = _now()
        with self.database.connection() as connection:
            connection.execute(
                """
                INSERT INTO push_subscriptions(id,workspace_id,kind,endpoint,secret,enabled,created_at)
                VALUES(?,?,?,?,?,1,?)
                ON CONFLICT(id) DO UPDATE SET
                  workspace_id=excluded.workspace_id, kind=excluded.kind,
                  endpoint=excluded.endpoint, secret=excluded.secret, enabled=1
                """,
                (value.id, workspace_id, value.kind, value.endpoint, value.secret, now),
            )
        return {"workspace_id": workspace_id, **value.model_dump(), "enabled": True, "created_at": now}

    def enqueue(self, workspace_id: str, event: PushEventInput) -> int:
        now = _now()
        count = 0
        with self.database.connection() as connection:
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

    def enqueue_all_workspaces(self, event: PushEventInput) -> int:
        with self.database.connection() as connection:
            workspace_ids = [
                row["workspace_id"]
                for row in connection.execute(
                    "SELECT DISTINCT workspace_id FROM push_subscriptions WHERE enabled=1"
                )
            ]
        return sum(self.enqueue(workspace_id, event) for workspace_id in workspace_ids)

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
            changed = connection.execute(
                """
                UPDATE push_outbox SET status='delivered',delivered_at=?
                WHERE id=? AND workspace_id=?
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
        async with httpx.AsyncClient(timeout=self.timeout_seconds) as client:
            for row in rows:
                body = row["payload_json"].encode()
                headers = {"Content-Type": "application/json", "X-GitHub-News-Event": row["event_type"]}
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
        return delivered

    def _mark(self, event_id: str, *, delivered: bool, attempts: int = 0) -> None:
        with self.database.connection() as connection:
            if delivered:
                connection.execute(
                    "UPDATE push_outbox SET status='delivered',delivered_at=? WHERE id=?",
                    (_now(), event_id),
                )
            else:
                delay = min(3600, 30 * (2 ** min(attempts, 7))) * 1000
                connection.execute(
                    "UPDATE push_outbox SET attempts=?,next_attempt_at=? WHERE id=?",
                    (attempts, _now() + delay, event_id),
                )


def _now() -> int:
    return int(time.time() * 1000)
