from fastapi import Request

from .collaboration_service import CollaborationService
from .feeds import FeedIngestor
from .gharchive_service import GhArchiveService
from .push_service import PushService
from .runtime import IngestionService
from .sync_service import SyncService


def feeds(request: Request) -> FeedIngestor:
    return request.app.state.feeds


def ingestion(request: Request) -> IngestionService:
    return request.app.state.ingestion


def sync(request: Request) -> SyncService:
    return request.app.state.sync


def collaboration(request: Request) -> CollaborationService:
    return request.app.state.collaboration


def push(request: Request) -> PushService:
    return request.app.state.push


def gharchive(request: Request) -> GhArchiveService:
    return request.app.state.gharchive
