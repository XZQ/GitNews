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
