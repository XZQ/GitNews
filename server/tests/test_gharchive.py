import gzip
import json

import httpx
import pytest

from app.db import Database
from app.gharchive_service import GhArchiveService


def test_gharchive_aggregation_and_trends(settings):
    database = Database(settings.database_path)
    database.initialize()
    service = GhArchiveService(database)
    events = [
        {"type": "WatchEvent", "repo": {"name": "Owner/Repo"}, "actor": {"login": "a"}},
        {"type": "WatchEvent", "repo": {"name": "owner/repo"}, "actor": {"login": "b"}},
        {"type": "PushEvent", "repo": {"name": "other/repo"}, "actor": {"login": "a"}},
    ]

    assert service.ingest_events("2026-07-16-1", events) == 3
    trends = service.trends(since_hour="2026-07-16-0", event_type="WatchEvent", limit=10)
    assert trends[0].repo == "owner/repo"
    assert trends[0].event_count == 2
    assert trends[0].unique_actors == 2


def test_trend_window_orders_numeric_hours_and_reads_legacy_rows(client):
    service = client.app.state.gharchive
    with client.app.state.database.connection() as connection:
        for hour in ("2", "9", "10", "20"):
            connection.execute(
                "INSERT INTO gharchive_stats VALUES(?,?,?,?,?,?)",
                (f"2026-10-12-{hour}", f"repo/hour-{hour}", "WatchEvent", 1, 1, 1000),
            )
    since_nine = service.trends(since_hour="2026-10-12-9", event_type=None, limit=10)
    assert {row.repo for row in since_nine} == {"repo/hour-9", "repo/hour-10", "repo/hour-20"}
    since_ten = service.trends(since_hour="2026-10-12-10", event_type=None, limit=10)
    assert {row.repo for row in since_ten} == {"repo/hour-10", "repo/hour-20"}
    assert service.trends(since_hour="2026-10-13-0", event_type=None, limit=10) == []
    assert service.trends(since_hour="2026-10-12-09", event_type=None, limit=10) == since_nine


def test_reingestion_replaces_legacy_hour_aliases(client):
    service = client.app.state.gharchive
    with client.app.state.database.connection() as connection:
        connection.execute(
            "INSERT INTO gharchive_stats VALUES(?,?,?,?,?,?)",
            ("2026-10-12-1", "owner/repo", "WatchEvent", 9, 9, 1000),
        )
        connection.execute(
            "INSERT INTO gharchive_stats VALUES(?,?,?,?,?,?)",
            ("2026-10-12-01", "owner/repo", "WatchEvent", 2, 2, 2000),
        )
    # Two old filename aliases represent reingestions of one hour, not two
    # independent samples. Keep the latest before any migration/reingestion.
    assert service.trends(since_hour="2026-10-12-0", event_type=None, limit=10)[0].event_count == 2
    event = {"type": "WatchEvent", "repo": {"name": "Owner/Repo"}, "actor": {"login": "a"}}
    service.ingest_events("2026-10-12-01", [event])
    service.ingest_events("2026-10-12-1", [event])
    trends = service.trends(since_hour="2026-10-12-0", event_type=None, limit=10)
    assert trends[0].event_count == 1
    with client.app.state.database.connection() as connection:
        assert connection.execute("SELECT hour FROM gharchive_stats").fetchall()[0][0] == "2026-10-12-01"


@pytest.mark.parametrize("hour", ["2026-02-30-1", "2026-13-01-0", "2026-10-12-24", "0000-10-12-1"])
def test_api_rejects_invalid_calendar_hours_before_download(client, auth_headers, hour):
    assert client.post("/v1/gharchive/ingest", headers=auth_headers, json={"hour": hour}).status_code == 422
    assert (
        client.get("/v1/gharchive/trends", headers=auth_headers, params={"since_hour": hour}).status_code
        == 422
    )


async def test_download_uses_unpadded_gharchive_filename(client, monkeypatch):
    payload = gzip.compress(
        json.dumps({"type": "WatchEvent", "repo": {"name": "owner/repo"}, "actor": {"login": "a"}}).encode()
    )
    requests = []

    def fetch(request):
        requests.append(str(request.url))
        return httpx.Response(200, content=payload)

    original = httpx.AsyncClient
    monkeypatch.setattr(
        httpx, "AsyncClient", lambda **kwargs: original(transport=httpx.MockTransport(fetch), **kwargs)
    )
    assert await client.app.state.gharchive.download_and_ingest("2026-10-12-01") == 1
    assert requests == ["https://data.gharchive.org/2026-10-12-1.json.gz"]
