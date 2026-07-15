from fastapi import APIRouter, Depends, HTTPException, Query

from ..auth import RequestContext, require_context
from ..deps import push
from ..models import PushEventInput, PushSubscriptionInput
from ..push_service import PushService, SubscriptionOwnershipError

router = APIRouter(prefix="/v1/push", tags=["push"])


@router.put("/subscriptions/{subscription_id}")
def subscribe(
    subscription_id: str,
    value: PushSubscriptionInput,
    context: RequestContext = Depends(require_context),
    service: PushService = Depends(push),
) -> dict[str, object]:
    if subscription_id != value.id:
        raise HTTPException(status_code=400, detail="subscription id mismatch")
    try:
        return service.subscribe(context.workspace_id, value)
    except SubscriptionOwnershipError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@router.post("/events")
def create_event(
    value: PushEventInput,
    context: RequestContext = Depends(require_context),
    service: PushService = Depends(push),
) -> dict[str, int]:
    return {"enqueued": service.enqueue(context.workspace_id, value)}


@router.get("/outbox")
def list_outbox(
    status: str = Query(default="pending", pattern="^(pending|delivered)$"),
    limit: int = Query(default=100, ge=1, le=1000),
    context: RequestContext = Depends(require_context),
    service: PushService = Depends(push),
) -> list[dict[str, object]]:
    return service.outbox(context.workspace_id, status=status, limit=limit)


@router.post("/outbox/{event_id}/ack")
def acknowledge(
    event_id: str,
    context: RequestContext = Depends(require_context),
    service: PushService = Depends(push),
) -> dict[str, bool]:
    return {"acknowledged": service.acknowledge(context.workspace_id, event_id)}
