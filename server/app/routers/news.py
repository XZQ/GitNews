from fastapi import APIRouter, Depends, Query

from ..auth import RequestContext, require_context
from ..deps import feeds, ingestion
from ..feeds import SOURCES, FeedIngestor
from ..models import IngestResult, NewsItem
from ..runtime import IngestionService

router = APIRouter(prefix="/v1", tags=["news"])


@router.get("/news", response_model=list[NewsItem])
def list_news(
    limit: int = Query(default=100, ge=1, le=500),
    source: str | None = None,
    since: int | None = Query(default=None, ge=0),
    _: RequestContext = Depends(require_context),
    service: FeedIngestor = Depends(feeds),
) -> list[NewsItem]:
    return service.list_items(limit=limit, source=source, since=since)


@router.get("/news/sources")
def list_sources(_: RequestContext = Depends(require_context)) -> list[dict[str, str]]:
    return [
        {"id": source.id, "name": source.name, "url": source.url, "category": source.category}
        for source in SOURCES
    ]


@router.post("/ingest/run", response_model=IngestResult)
async def run_ingestion(
    _: RequestContext = Depends(require_context),
    service: IngestionService = Depends(ingestion),
) -> IngestResult:
    return await service.run_feeds()
