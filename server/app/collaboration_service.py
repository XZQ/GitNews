from __future__ import annotations

from .db import Database
from .models import AnnotationInput, WorkspaceMemberInput


class CollaborationService:
    def __init__(self, database: Database) -> None:
        self.database = database

    def upsert_member(self, workspace_id: str, member: WorkspaceMemberInput, now: int) -> dict[str, object]:
        with self.database.connection() as connection:
            connection.execute(
                """
                INSERT INTO workspace_members(workspace_id,member_id,display_name,role,updated_at)
                VALUES(?,?,?,?,?)
                ON CONFLICT(workspace_id,member_id) DO UPDATE SET
                  display_name=excluded.display_name, role=excluded.role, updated_at=excluded.updated_at
                """,
                (workspace_id, member.member_id, member.display_name, member.role, now),
            )
        return {"workspace_id": workspace_id, **member.model_dump(), "updated_at": now}

    def list_members(self, workspace_id: str) -> list[dict[str, object]]:
        with self.database.connection() as connection:
            rows = connection.execute(
                "SELECT * FROM workspace_members WHERE workspace_id=? ORDER BY role,display_name",
                (workspace_id,),
            ).fetchall()
        return [dict(row) for row in rows]

    def upsert_annotation(self, workspace_id: str, annotation: AnnotationInput) -> dict[str, object]:
        with self.database.connection() as connection:
            existing = connection.execute(
                "SELECT version FROM annotations WHERE id=? AND workspace_id=?",
                (annotation.id, workspace_id),
            ).fetchone()
            if existing is not None and existing["version"] > annotation.version:
                raise ValueError("annotation version conflict")
            connection.execute(
                """
                INSERT INTO annotations(id,workspace_id,item_id,author_id,body,version,updated_at)
                VALUES(?,?,?,?,?,?,?)
                ON CONFLICT(id) DO UPDATE SET
                  item_id=excluded.item_id, author_id=excluded.author_id, body=excluded.body,
                  version=excluded.version, updated_at=excluded.updated_at
                """,
                (
                    annotation.id,
                    workspace_id,
                    annotation.item_id,
                    annotation.author_id,
                    annotation.body,
                    annotation.version,
                    annotation.updated_at,
                ),
            )
        return {"workspace_id": workspace_id, **annotation.model_dump()}

    def list_annotations(self, workspace_id: str, item_id: str) -> list[dict[str, object]]:
        with self.database.connection() as connection:
            rows = connection.execute(
                """
                SELECT * FROM annotations WHERE workspace_id=? AND item_id=?
                ORDER BY updated_at
                """,
                (workspace_id, item_id),
            ).fetchall()
        return [dict(row) for row in rows]
