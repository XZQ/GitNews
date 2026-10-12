from fastapi import APIRouter, Depends, HTTPException, Query

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
    cursor: str | None = Query(default=None, min_length=1, max_length=1000),
    namespace: str | None = Query(default=None, min_length=1, max_length=80),
    record_id: str | None = Query(default=None, min_length=1, max_length=200),
    context: RequestContext = Depends(require_context),
    service: SyncService = Depends(sync),
) -> list[SyncRecord]:
    try:
        return service.pull(
            context.workspace_id,
            since=since,
            limit=limit,
            cursor=cursor,
            namespace=namespace,
            record_id=record_id,
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
