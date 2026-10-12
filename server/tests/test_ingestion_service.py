from concurrent.futures import ThreadPoolExecutor

from app.db import Database
from app.feeds import FeedIngestor
from app.models import NewsItem, PushSubscriptionInput
from app.push_service import PushService
from app.runtime import IngestionService


def item(**changes):
    return NewsItem(
        **{
            "id": "news-1",
            "title": "A new article",
            "source": "Fixture",
            "category": "industry",
            "url": "https://example.invalid/article",
            "published_at": 1000,
            **changes,
        }
    )


def subscribe(push, workspace):
    push.subscribe(workspace, PushSubscriptionInput(id=f"device-{workspace}", kind="fcm", endpoint="fixture"))


async def test_outbox_failure_rolls_back_news_and_all_workspaces_then_retries(client, monkeypatch):
    app = client.app
    subscribe(app.state.push, "a")
    subscribe(app.state.push, "b")
    app.state.feeds.persist([item(id="existing", title="Original")])

    async def fetch():
        return [item(), item(id="existing", title="Updated")], []

    monkeypatch.setattr(app.state.feeds, "fetch_all", fetch)
    original = app.state.push._enqueue_in_transaction
    calls = 0

    def fail_after_one_workspace(workspace, event, connection):
        nonlocal calls
        calls += 1
        if calls == 2:
            raise RuntimeError("fixture outbox failure")
        return original(workspace, event, connection)

    monkeypatch.setattr(app.state.push, "_enqueue_in_transaction", fail_after_one_workspace)
    failed = await app.state.ingestion.run_feeds()
    assert failed.status == "failed"
    assert app.state.feeds.list_items(limit=10, source=None, since=None) == [
        item(id="existing", title="Original")
    ]
    assert app.state.push.outbox("a", status="pending", limit=10) == []
    assert app.state.push.outbox("b", status="pending", limit=10) == []

    monkeypatch.setattr(app.state.push, "_enqueue_in_transaction", original)
    assert (await app.state.ingestion.run_feeds()).status == "ok"
    for workspace in ("a", "b"):
        events = app.state.push.outbox(workspace, status="pending", limit=10)
        assert len(events) == 1
        assert events[0]["payload"]["count"] == 1
        assert events[0]["payload"]["items"][0]["id"] == "news-1"
    assert (await app.state.ingestion.run_feeds()).status == "ok"
    assert len(app.state.push.outbox("a", status="pending", limit=10)) == 1
    with app.state.database.connection() as connection:
        assert [row[0] for row in connection.execute("SELECT status FROM ingest_runs ORDER BY rowid")] == [
            "failed",
            "ok",
            "ok",
        ]
    # Reopening the database preserves the completed news/outbox transaction.
    reopened = Database(app.state.settings.database_path)
    reopened.initialize()
    assert len(PushService(reopened).outbox("a", status="pending", limit=10)) == 1


def test_concurrent_ingestion_instances_enqueue_each_article_once(client):
    database = client.app.state.database
    push = PushService(database)
    subscribe(push, "a")

    def persist(_):
        instance = Database(database.path)
        IngestionService(instance, FeedIngestor(instance), PushService(instance))._persist_and_enqueue(
            [item()]
        )

    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(persist, range(8)))
    assert len(FeedIngestor(database).list_items(limit=10, source=None, since=None)) == 1
    assert len(push.outbox("a", status="pending", limit=10)) == 1
