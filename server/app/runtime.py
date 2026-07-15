from __future__ import annotations

import asyncio
import time
import uuid

from .config import Settings
from .db import Database
from .feeds import FeedIngestor
from .models import IngestResult, PushEventInput
from .push_service import PushService


class IngestionService:
    def __init__(self, database: Database, feeds: FeedIngestor, push: PushService) -> None:
        self.database = database
        self.feeds = feeds
        self.push = push
        self._lock = asyncio.Lock()

    async def run_feeds(self) -> IngestResult:
        if self._lock.locked():
            return IngestResult(run_id="already-running", status="partial", item_count=0, errors=["busy"])
        async with self._lock:
            run_id = uuid.uuid4().hex
            started = _now()
            try:
                items, errors = await self.feeds.fetch_all()
                new_items = self.feeds.persist(items)
                if new_items:
                    self.push.enqueue_all_workspaces(
                        PushEventInput(
                            event_type="news.items.created",
                            payload={
                                "count": len(new_items),
                                "items": [item.model_dump() for item in new_items[:20]],
                            },
                        )
                    )
                status = "partial" if errors else "ok"
                result = IngestResult(
                    run_id=run_id,
                    status=status,
                    item_count=len(items),
                    errors=errors,
                )
            except Exception as error:  # noqa: BLE001 - persist failed run for operators
                result = IngestResult(
                    run_id=run_id,
                    status="failed",
                    item_count=0,
                    errors=[type(error).__name__],
                )
            self._record_run(result, started)
            return result

    def _record_run(self, result: IngestResult, started: int) -> None:
        with self.database.connection() as connection:
            connection.execute(
                """
                INSERT INTO ingest_runs(id,kind,status,item_count,detail,started_at,finished_at)
                VALUES(?,?,?,?,?,?,?)
                """,
                (
                    result.run_id,
                    "feeds",
                    result.status,
                    result.item_count,
                    ",".join(result.errors),
                    started,
                    _now(),
                ),
            )


class Scheduler:
    def __init__(
        self,
        settings: Settings,
        ingestion: IngestionService,
        push: PushService,
    ) -> None:
        self.settings = settings
        self.ingestion = ingestion
        self.push = push
        self._tasks: list[asyncio.Task[None]] = []

    def start(self) -> None:
        if not self.settings.scheduler_enabled or self._tasks:
            return
        self._tasks = [
            asyncio.create_task(self._feed_loop(), name="feed-ingestion"),
            asyncio.create_task(self._push_loop(), name="push-dispatch"),
        ]

    async def stop(self) -> None:
        for task in self._tasks:
            task.cancel()
        await asyncio.gather(*self._tasks, return_exceptions=True)
        self._tasks.clear()

    async def _feed_loop(self) -> None:
        while True:
            await self.ingestion.run_feeds()
            await asyncio.sleep(self.settings.ingest_interval_seconds)

    async def _push_loop(self) -> None:
        while True:
            await self.push.dispatch_webhooks()
            await asyncio.sleep(self.settings.push_interval_seconds)


def _now() -> int:
    return int(time.time() * 1000)
