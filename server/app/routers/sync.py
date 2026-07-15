from fastapi import APIRouter, Depends, Query

from ..auth import RequestContext, require_context
from ..deps import sync
from ..models import SyncPushRequest, SyncPushResult, SyncRecord
from ..sync_service import SyncService

router = APIRouter(prefix="/v1/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResult)
def push_records(
    value: SyncPushRequest,
    context: RequestContext = Depends(require_context),
    service: SyncService = Depends(sync),
) -> SyncPushResult:
    return service.push(context.workspace_id, value.records)


@router.get("/pull", response_model=list[SyncRecord])
def pull_records(
    since: int = Query(default=0, ge=0),
    limit: int = Query(default=1000, ge=1, le=5000),
    context: RequestContext = Depends(require_context),
    service: SyncService = Depends(sync),
) -> list[SyncRecord]:
    return service.pull(context.workspace_id, since=since, limit=limit)
