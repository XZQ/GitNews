from __future__ import annotations

import asyncio
import logging
import time
import uuid

from .config import Settings
from .db import Database
from .feeds import FeedIngestor
from .models import IngestResult, NewsItem, PushEventInput
from .push_service import PushService

logger = logging.getLogger(__name__)


class IngestionService:
    def __init__(self, database: Database, feeds: FeedIngestor, push: PushService) -> None:
        self.database = database
        self.feeds = feeds
        self.push = push
        # Check-and-set with no await in between is atomic on the event loop;
        # a locked() check followed by `async with` would let two concurrent
        # callers both pass the check and run the ingestion twice.
        self._running = False

    async def run_feeds(self) -> IngestResult:
        if self._running:
            return IngestResult(run_id="already-running", status="partial", item_count=0, errors=["busy"])
        self._running = True
        try:
            run_id = uuid.uuid4().hex
            started = _now()
            try:
                items, errors = await self.feeds.fetch_all()
                self._persist_and_enqueue(items)
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
        finally:
            self._running = False

    def _persist_and_enqueue(self, items: list[NewsItem]) -> None:
        with self.database.connection() as connection:
            # Also serializes multiple service instances: only the transaction
            # inserting a previously unseen article creates its notifications.
            connection.execute("BEGIN IMMEDIATE")
            new_items = self.feeds.persist_in_transaction(items, connection)
            if new_items:
                self.push.enqueue_all_workspaces(
                    PushEventInput(
                        event_type="news.items.created",
                        payload={
                            "count": len(new_items),
                            "items": [item.model_dump() for item in new_items[:20]],
                        },
                    ),
                    connection=connection,
                )

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
        for task in self._tasks:
            task.add_done_callback(self._on_task_done)

    async def stop(self) -> None:
        for task in self._tasks:
            task.cancel()
        await asyncio.gather(*self._tasks, return_exceptions=True)
        self._tasks.clear()

    @staticmethod
    def _on_task_done(task: asyncio.Task[None]) -> None:
        # The loops below catch their own errors; a task that still dies is a
        # bug or cancellation, and operators must not lose that silently.
        if not task.cancelled() and task.exception() is not None:
            logger.error("scheduler task %s stopped unexpectedly", task.get_name(), exc_info=task.exception())

    async def _feed_loop(self) -> None:
        while True:
            try:
                await self.ingestion.run_feeds()
            except Exception:  # noqa: BLE001 - one bad run must not kill the schedule
                logger.exception("scheduled feed ingestion failed")
            await asyncio.sleep(self.settings.ingest_interval_seconds)

    async def _push_loop(self) -> None:
        while True:
            try:
                await self.push.dispatch_webhooks()
            except Exception:  # noqa: BLE001 - one bad dispatch must not kill the schedule
                logger.exception("scheduled webhook dispatch failed")
            await asyncio.sleep(self.settings.push_interval_seconds)


def _now() -> int:
    return int(time.time() * 1000)
