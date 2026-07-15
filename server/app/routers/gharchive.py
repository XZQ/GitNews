from fastapi import APIRouter, Depends, Query

from ..auth import RequestContext, require_context
from ..deps import gharchive
from ..gharchive_service import GhArchiveService
from ..models import GhArchiveIngestRequest, GhArchiveTrend

router = APIRouter(prefix="/v1/gharchive", tags=["gharchive"])


@router.post("/ingest")
async def ingest_hour(
    value: GhArchiveIngestRequest,
    _: RequestContext = Depends(require_context),
    service: GhArchiveService = Depends(gharchive),
) -> dict[str, object]:
    count = await service.download_and_ingest(value.hour)
    return {"hour": value.hour, "events": count}


@router.get("/trends", response_model=list[GhArchiveTrend])
def trends(
    since_hour: str = Query(pattern=r"^\d{4}-\d{2}-\d{2}-\d{1,2}$"),
    event_type: str | None = None,
    limit: int = Query(default=100, ge=1, le=1000),
    _: RequestContext = Depends(require_context),
    service: GhArchiveService = Depends(gharchive),
) -> list[GhArchiveTrend]:
    return service.trends(since_hour=since_hour, event_type=event_type, limit=limit)
