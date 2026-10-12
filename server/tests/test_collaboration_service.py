import threading
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager

from app.collaboration_service import CollaborationService
from app.models import AnnotationInput


def annotation(**changes):
    return AnnotationInput(
        **{
            "id": "shared-note",
            "item_id": "news-1",
            "author_id": "alice",
            "body": "Original private note",
            "version": 1,
            "updated_at": 1000,
            **changes,
        }
    )


def test_annotation_id_collision_cannot_modify_another_workspace(client, auth_headers):
    value = annotation().model_dump()
    path = "/v1/collaboration/annotations/shared-note"
    assert client.put(path, headers=auth_headers, json=value).status_code == 200
    other = {**auth_headers, "X-Workspace-ID": "workspace-b"}
    denied = client.put(path, headers=other, json={**value, "body": "Other workspace", "version": 2})
    assert denied.status_code == 409
    original = client.get("/v1/collaboration/annotations/news-1", headers=auth_headers).json()
    assert original[0]["body"] == value["body"]
    assert original[0]["version"] == 1
    assert client.get("/v1/collaboration/annotations/news-1", headers=other).json() == []


def test_annotation_equal_version_requires_identical_content(client, auth_headers):
    value = annotation().model_dump()
    path = "/v1/collaboration/annotations/shared-note"
    first = client.put(path, headers=auth_headers, json=value)
    retry = client.put(path, headers=auth_headers, json={**value, "updated_at": 2000})
    assert retry.status_code == 200
    assert retry.json() == first.json()
    for changed in ({"body": "Changed"}, {"author_id": "bob"}, {"item_id": "news-2"}):
        assert client.put(path, headers=auth_headers, json={**value, **changed}).status_code == 409


def test_concurrent_annotation_update_keeps_highest_version(client):
    base = client.app.state.database
    CollaborationService(base).upsert_annotation("a", annotation())
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
            if "SELECT" in query and "FROM annotations" in query:
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
        try:
            return CollaborationService(CoordinatedDatabase()).upsert_annotation(
                "a", annotation(version=version, body=f"Version {version}")
            )
        except ValueError:
            return None

    with ThreadPoolExecutor(max_workers=2) as pool:
        high = pool.submit(write, 3)
        assert high_selected.wait(5)
        low = pool.submit(write, 2)
        assert high.result(timeout=10)["version"] == 3
        assert low.result(timeout=10) is None
    assert CollaborationService(base).list_annotations("a", "news-1")[0]["version"] == 3
