from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .collaboration_service import CollaborationService
from .config import Settings
from .db import Database
from .feeds import FeedIngestor
from .gharchive_service import GhArchiveService
from .models import HealthResponse
from .push_service import PushService
from .routers import collaboration, gharchive, news, push, sync
from .runtime import IngestionService, Scheduler
from .sync_service import SyncService


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved = settings or Settings.from_env()
    database = Database(resolved.database_path)
    database.initialize()
    feeds = FeedIngestor(database, resolved.request_timeout_seconds)
    push_service = PushService(database, resolved.request_timeout_seconds)
    ingestion = IngestionService(database, feeds, push_service)
    scheduler = Scheduler(resolved, ingestion, push_service)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        scheduler.start()
        try:
            yield
        finally:
            await scheduler.stop()

    app = FastAPI(
        title="AI资讯 Self-hosted Server",
        version="0.1.0",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.state.settings = resolved
    app.state.database = database
    app.state.feeds = feeds
    app.state.push = push_service
    app.state.ingestion = ingestion
    app.state.sync = SyncService(database)
    app.state.collaboration = CollaborationService(database)
    app.state.gharchive = GhArchiveService(database, resolved.request_timeout_seconds)
    app.state.scheduler = scheduler

    @app.get("/health", response_model=HealthResponse, tags=["operations"])
    def health(request: Request) -> HealthResponse:
        return HealthResponse(
            status="ok",
            database=request.app.state.database.health(),
            scheduler_enabled=resolved.scheduler_enabled,
        )

    for router in (news.router, sync.router, collaboration.router, push.router, gharchive.router):
        app.include_router(router)
    return app


# `uvicorn app.main:app` 兼容入口。PEP 562 惰性构造:import 本模块不再
# 触发 Settings.from_env()(它会在缺少 master key 时 fail-fast),
# 测试与工具可安全 import create_app 而不要求环境变量就绪。
_app: FastAPI | None = None


def __getattr__(name: str) -> FastAPI:
    global _app  # noqa: PLW0603 - module-level singleton for the ASGI entrypoint
    if name == "app":
        if _app is None:
            _app = create_app()
        return _app
    raise AttributeError(name)
