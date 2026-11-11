import asyncio

from app.config import Settings
from app.models import IngestResult
from app.runtime import Scheduler


def make_settings(tmp_path, **overrides) -> Settings:
    base = {
        "database_path": tmp_path / "runtime.db",
        "master_key": "test-secret",
        "scheduler_enabled": True,
        "ingest_interval_seconds": 0,
        "push_interval_seconds": 0,
        "request_timeout_seconds": 5,
    }
    return Settings(**{**base, **overrides})


async def test_push_loop_survives_dispatch_errors(client, tmp_path):
    calls = []
    recovered = asyncio.Event()

    class FlakyPush:
        async def dispatch_webhooks(self) -> int:
            calls.append(len(calls))
            if len(calls) == 1:
                raise RuntimeError("fixture transient failure")
            recovered.set()
            return 0

    scheduler = Scheduler(make_settings(tmp_path), client.app.state.ingestion, FlakyPush())
    task = asyncio.create_task(scheduler._push_loop())
    try:
        await asyncio.wait_for(recovered.wait(), timeout=5)
    finally:
        task.cancel()
        await asyncio.gather(task, return_exceptions=True)
    # One bad dispatch must not kill the schedule: the loop ran again.
    assert len(calls) >= 2


async def test_feed_loop_survives_ingestion_errors(client, tmp_path):
    calls = []
    recovered = asyncio.Event()

    class FlakyIngestion:
        async def run_feeds(self) -> IngestResult:
            calls.append(len(calls))
            if len(calls) == 1:
                raise RuntimeError("fixture transient failure")
            recovered.set()
            return IngestResult(run_id="r", status="ok", item_count=0)

    scheduler = Scheduler(make_settings(tmp_path), FlakyIngestion(), client.app.state.push)
    task = asyncio.create_task(scheduler._feed_loop())
    try:
        await asyncio.wait_for(recovered.wait(), timeout=5)
    finally:
        task.cancel()
        await asyncio.gather(task, return_exceptions=True)
    assert len(calls) >= 2


async def test_concurrent_run_feeds_returns_busy_without_double_run(client, monkeypatch):
    ingestion = client.app.state.ingestion
    started = asyncio.Event()
    release = asyncio.Event()
    runs = []

    async def slow_fetch():
        runs.append(1)
        started.set()
        await release.wait()
        return [], []

    monkeypatch.setattr(client.app.state.feeds, "fetch_all", slow_fetch)
    first = asyncio.create_task(ingestion.run_feeds())
    await asyncio.wait_for(started.wait(), timeout=5)
    # While the first run is in flight the second caller must get the busy
    # result immediately, not queue up and re-run the ingestion afterwards.
    second = await asyncio.wait_for(ingestion.run_feeds(), timeout=5)
    assert second.run_id == "already-running"
    release.set()
    assert (await first).status == "ok"
    assert len(runs) == 1
    # The flag resets so a later run is accepted.
    assert (await ingestion.run_feeds()).status == "ok"


async def test_run_feeds_releases_busy_flag_after_record_failure(client, monkeypatch):
    ingestion = client.app.state.ingestion
    original_record = ingestion._record_run

    async def fetch():
        return [], []

    def broken_record(result, started):
        raise RuntimeError("fixture record failure")

    monkeypatch.setattr(client.app.state.feeds, "fetch_all", fetch)
    monkeypatch.setattr(ingestion, "_record_run", broken_record)
    try:
        await ingestion.run_feeds()
    except RuntimeError:
        pass
    monkeypatch.setattr(ingestion, "_record_run", original_record)
    # A crash inside the run must not leave the service permanently busy.
    assert (await ingestion.run_feeds()).status == "ok"
