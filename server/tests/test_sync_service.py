import sqlite3
import threading
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager

import pytest

from app.db import Database
from app.models import SyncRecordInput
from app.sync_service import SyncService


def record(record_id="shared", **changes):
    return SyncRecordInput(
        **{
            "namespace": "preferences",
            "record_id": record_id,
            "payload": {"mode": "dark"},
            "version": 1,
            "updated_at": 1000,
            **changes,
        }
    )


def test_same_version_is_idempotent_only_for_the_same_content(client):
    service = client.app.state.sync
    assert service.push("a", [record()]).accepted == 1
    before = service.pull("a", since=0, limit=10)[0]
    assert service.push("a", [record(updated_at=2000)]).accepted == 1
    assert service.pull("a", since=0, limit=10)[0] == before
    conflict = service.push("a", [record(payload={"mode": "light"})])
    assert conflict.accepted == 0
    assert conflict.conflicts == [before]
    deleted = service.push("a", [record(deleted=True)])
    assert deleted.accepted == 0
    assert service.pull("a", since=0, limit=10)[0] == before


def test_cursor_pages_equal_timestamps_and_sees_clock_regression(client):
    service = client.app.state.sync
    service.push("a", [record(str(index)) for index in range(5)])
    first = service.pull("a", since=0, limit=2, cursor="start")
    second = service.pull("a", since=0, limit=2, cursor=first[-1].cursor)
    third = service.pull("a", since=0, limit=2, cursor=second[-1].cursor)
    assert [row.record_id for row in [*first, *second, *third]] == [str(index) for index in range(5)]
    checkpoint = third[-1].cursor
    service.push("a", [record("0", version=2, updated_at=1)])
    service.push("a", [record("1", version=2, deleted=True, updated_at=1000)])
    changed = service.pull("a", since=999999, limit=10, cursor=checkpoint)
    assert [(row.record_id, row.deleted) for row in changed] == [("0", False), ("1", True)]
    assert changed[0].updated_at == 1
    assert service.pull("b", since=0, limit=10) == []


def test_legacy_pull_preserves_timestamp_and_tiebreak_order(client):
    service = client.app.state.sync
    service.push(
        "a",
        [
            record("late", updated_at=3000),
            record("early-z", namespace="z"),
            record("early-b", namespace="a"),
            record("early-a", namespace="a"),
            record("middle", updated_at=2000),
        ],
    )
    rows = service.pull("a", since=0, limit=10)
    assert [row.record_id for row in rows] == ["early-a", "early-b", "early-z", "middle", "late"]
    first = service.pull("a", since=0, limit=1)
    second = service.pull("a", since=first[-1].updated_at, limit=1)
    third = service.pull("a", since=second[-1].updated_at, limit=1)
    assert [row.record_id for row in [*first, *second, *third]] == ["early-a", "middle", "late"]


def test_revision_paging_starts_before_records_with_reverse_client_times(client, auth_headers):
    service = client.app.state.sync
    service.push(
        "workspace-a",
        [
            record("late", updated_at=3000),
            record("early", updated_at=1000),
            record("middle", updated_at=2000),
            record("same-time", updated_at=1000),
        ],
    )
    first = client.get(
        "/v1/sync/pull", headers=auth_headers, params={"cursor": "start", "since": 999999, "limit": 2}
    )
    assert first.status_code == 200
    first_rows = first.json()
    assert [row["record_id"] for row in first_rows] == ["late", "early"]
    second = client.get(
        "/v1/sync/pull", headers=auth_headers, params={"cursor": first_rows[-1]["cursor"], "limit": 2}
    )
    assert second.status_code == 200
    second_rows = second.json()
    assert [row["record_id"] for row in second_rows] == ["middle", "same-time"]
    checkpoint = second_rows[-1]["cursor"]
    assert service.pull("workspace-a", since=0, limit=2, cursor=checkpoint) == []
    service.push("workspace-a", [record("early", version=2, updated_at=500)])
    assert service.pull("workspace-a", since=0, limit=2, cursor=checkpoint)[0].record_id == "early"


def test_pull_filters_and_cursor_validation(client, auth_headers):
    service = client.app.state.sync
    service.push("workspace-a", [record(str(i), namespace="noise") for i in range(1001)])
    service.push("workspace-a", [record(namespace="app_config", deleted=True)])
    response = client.get(
        "/v1/sync/pull",
        headers=auth_headers,
        params={"since": 0, "limit": 1, "namespace": "app_config", "record_id": "shared"},
    )
    assert response.status_code == 200
    assert response.json()[0]["deleted"] is True
    assert response.json()[0]["namespace"] == "app_config"
    assert len(service.pull("workspace-a", since=0, limit=2000, namespace="noise")) == 1001
    assert len(service.pull("workspace-a", since=0, limit=2000, record_id="shared")) == 1
    cursor = response.json()[0]["cursor"]
    assert client.get("/v1/sync/pull", headers=auth_headers, params={"cursor": "bad!"}).status_code == 400
    assert (
        client.get(
            "/v1/sync/pull",
            headers={**auth_headers, "X-Workspace-ID": "b"},
            params={"cursor": cursor},
        ).status_code
        == 400
    )


def test_legacy_database_migration_preserves_records_and_durable_revisions(tmp_path):
    path = tmp_path / "legacy.db"
    with sqlite3.connect(path) as connection:
        connection.execute(
            "CREATE TABLE sync_records (workspace_id TEXT NOT NULL, namespace TEXT NOT NULL, "
            "record_id TEXT NOT NULL, payload_json TEXT NOT NULL, version INTEGER NOT NULL, "
            "deleted INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL, "
            "PRIMARY KEY(workspace_id,namespace,record_id))"
        )
        connection.executemany(
            "INSERT INTO sync_records VALUES(?,?,?,?,?,?,?)",
            [
                ("a", "preferences", "one", '{"mode":"dark"}', 3, 0, 1000),
                ("a", "preferences", "two", "{}", 4, 1, 1000),
            ],
        )

    class InterruptedMigration(Database):
        def _migrate_sync_revisions(self, connection):
            super()._migrate_sync_revisions(connection)
            raise RuntimeError("fixture interrupted migration")

    with pytest.raises(RuntimeError, match="interrupted migration"):
        InterruptedMigration(path).initialize()
    with sqlite3.connect(path) as connection:
        assert "revision" not in {row[1] for row in connection.execute("PRAGMA table_info(sync_records)")}
        assert connection.execute("SELECT COUNT(*) FROM sync_records").fetchone()[0] == 2
    database = Database(path)
    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(lambda _: Database(path).initialize(), range(8)))
    service = SyncService(database)
    rows = service.pull("a", since=0, limit=10)
    assert [(row.record_id, row.version, row.deleted) for row in rows] == [
        ("one", 3, False),
        ("two", 4, True),
    ]
    assert rows[0].payload == {"mode": "dark"}
    database.initialize()
    assert service.pull("a", since=0, limit=10) == rows
    service.push("a", [record("three", updated_at=1)])
    fresh = service.pull("a", since=0, limit=10, cursor=rows[-1].cursor)
    assert len(fresh) == 1
    assert fresh[0].revision > rows[-1].revision


def test_concurrent_version_check_cannot_overwrite_a_newer_commit(client):
    base = client.app.state.database
    SyncService(base).push("a", [record()])
    high_selected = threading.Event()
    low_entered = threading.Event()
    high_committed = threading.Event()
    thread = threading.local()

    class Cursor:
        def __init__(self, cursor):
            self.cursor = cursor

        def fetchone(self):
            row = self.cursor.fetchone()
            if thread.version == 3:
                high_selected.set()
                assert low_entered.wait(5)
            else:
                low_entered.set()
                assert high_committed.wait(5)
            return row

    class Connection:
        def __init__(self, connection):
            self.connection = connection

        def execute(self, query, parameters=()):
            if query == "BEGIN IMMEDIATE" and thread.version == 2:
                low_entered.set()
            cursor = self.connection.execute(query, parameters)
            if query.startswith("SELECT * FROM sync_records"):
                return Cursor(cursor)
            return cursor

    class CoordinatedDatabase:
        @contextmanager
        def connection(self):
            with base.connection() as connection:
                yield Connection(connection)
            if thread.version == 3:
                high_committed.set()

    def write(version):
        thread.version = version
        return SyncService(CoordinatedDatabase()).push("a", [record(version=version, payload={"v": version})])

    with ThreadPoolExecutor(max_workers=2) as pool:
        high = pool.submit(write, 3)
        assert high_selected.wait(5)
        low = pool.submit(write, 2)
        assert high.result(timeout=10).accepted == 1
        conflict = low.result(timeout=10)
    assert conflict.accepted == 0
    assert conflict.conflicts[0].version == 3
    assert SyncService(base).pull("a", since=0, limit=10)[0].version == 3


@pytest.mark.parametrize("cursor", ["", "é", "eyJ2IjoxLCJ3IjoiYSIsInIiOnRydWV9"])
def test_service_rejects_malformed_cursor(client, cursor):
    with pytest.raises(ValueError, match="invalid sync cursor"):
        client.app.state.sync.pull("a", since=0, limit=10, cursor=cursor)
