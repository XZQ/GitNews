from __future__ import annotations

from .db import Database, json_text, parse_json
from .models import SyncPushResult, SyncRecord, SyncRecordInput
from .sync_cursor import decode_cursor, encode_cursor


class SyncService:
    def __init__(self, database: Database) -> None:
        self.database = database

    def push(self, workspace_id: str, records: list[SyncRecordInput]) -> SyncPushResult:
        accepted = 0
        conflicts: list[SyncRecord] = []
        with self.database.connection() as connection:
            connection.execute("BEGIN IMMEDIATE")
            for record in records:
                existing = connection.execute(
                    "SELECT * FROM sync_records WHERE workspace_id=? AND namespace=? AND record_id=?",
                    (workspace_id, record.namespace, record.record_id),
                ).fetchone()
                if existing is not None and existing["version"] > record.version:
                    conflicts.append(_sync_record(existing))
                    continue
                payload_json = json_text(record.payload)
                if existing is not None and existing["version"] == record.version:
                    if (
                        existing["payload_json"] != payload_json
                        or bool(existing["deleted"]) != record.deleted
                    ):
                        conflicts.append(_sync_record(existing))
                    else:
                        # Retrying an accepted write must not move the cursor or
                        # rewrite its original client timestamp.
                        accepted += 1
                    continue
                revision = connection.execute(
                    "UPDATE sync_clock SET revision=revision+1 WHERE singleton=1 RETURNING revision"
                ).fetchone()[0]
                connection.execute(
                    """
                    INSERT INTO sync_records(
                      workspace_id,namespace,record_id,payload_json,version,deleted,updated_at,revision
                    ) VALUES(?,?,?,?,?,?,?,?)
                    ON CONFLICT(workspace_id,namespace,record_id) DO UPDATE SET
                      payload_json=excluded.payload_json, version=excluded.version,
                      deleted=excluded.deleted, updated_at=excluded.updated_at, revision=excluded.revision
                    """,
                    (
                        workspace_id,
                        record.namespace,
                        record.record_id,
                        payload_json,
                        record.version,
                        int(record.deleted),
                        record.updated_at,
                        revision,
                    ),
                )
                accepted += 1
        return SyncPushResult(accepted=accepted, conflicts=conflicts)

    def pull(
        self,
        workspace_id: str,
        *,
        since: int,
        limit: int,
        cursor: str | None = None,
        namespace: str | None = None,
        record_id: str | None = None,
    ) -> list[SyncRecord]:
        clauses = ["workspace_id=?"]
        args: list[object] = [workspace_id]
        if cursor is None:
            clauses.append("updated_at>?")
            args.append(since)
            order_by = "updated_at, namespace, record_id"
        else:
            clauses.append("revision>?")
            args.append(decode_cursor(cursor, workspace_id))
            order_by = "revision"
        for name, value in (("namespace", namespace), ("record_id", record_id)):
            if value is not None:
                clauses.append(f"{name}=?")
                args.append(value)
        with self.database.connection() as connection:
            rows = connection.execute(
                f"""
                SELECT * FROM sync_records
                WHERE {" AND ".join(clauses)}
                ORDER BY {order_by} LIMIT ?
                """,
                [*args, limit],
            ).fetchall()
        return [_sync_record(row) for row in rows]


def _sync_record(row: object) -> SyncRecord:
    return SyncRecord(
        workspace_id=row["workspace_id"],
        namespace=row["namespace"],
        record_id=row["record_id"],
        payload=parse_json(row["payload_json"]),
        version=row["version"],
        deleted=bool(row["deleted"]),
        updated_at=row["updated_at"],
        revision=row["revision"],
        cursor=encode_cursor(row["workspace_id"], row["revision"]),
    )
