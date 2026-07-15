from __future__ import annotations

from .db import Database, json_text, parse_json
from .models import SyncPushResult, SyncRecord, SyncRecordInput


class SyncService:
    def __init__(self, database: Database) -> None:
        self.database = database

    def push(self, workspace_id: str, records: list[SyncRecordInput]) -> SyncPushResult:
        accepted = 0
        conflicts: list[SyncRecord] = []
        with self.database.connection() as connection:
            for record in records:
                existing = connection.execute(
                    "SELECT * FROM sync_records WHERE workspace_id=? AND namespace=? AND record_id=?",
                    (workspace_id, record.namespace, record.record_id),
                ).fetchone()
                if existing is not None and existing["version"] > record.version:
                    conflicts.append(_sync_record(existing))
                    continue
                connection.execute(
                    """
                    INSERT INTO sync_records(
                      workspace_id,namespace,record_id,payload_json,version,deleted,updated_at
                    ) VALUES(?,?,?,?,?,?,?)
                    ON CONFLICT(workspace_id,namespace,record_id) DO UPDATE SET
                      payload_json=excluded.payload_json, version=excluded.version,
                      deleted=excluded.deleted, updated_at=excluded.updated_at
                    """,
                    (
                        workspace_id,
                        record.namespace,
                        record.record_id,
                        json_text(record.payload),
                        record.version,
                        int(record.deleted),
                        record.updated_at,
                    ),
                )
                accepted += 1
        return SyncPushResult(accepted=accepted, conflicts=conflicts)

    def pull(self, workspace_id: str, *, since: int, limit: int) -> list[SyncRecord]:
        with self.database.connection() as connection:
            rows = connection.execute(
                """
                SELECT * FROM sync_records
                WHERE workspace_id=? AND updated_at>?
                ORDER BY updated_at, namespace, record_id LIMIT ?
                """,
                (workspace_id, since, limit),
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
    )
