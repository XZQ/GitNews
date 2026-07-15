import time

from fastapi import APIRouter, Depends, HTTPException

from ..auth import RequestContext, require_context
from ..collaboration_service import CollaborationService
from ..deps import collaboration
from ..models import AnnotationInput, WorkspaceMemberInput

router = APIRouter(prefix="/v1/collaboration", tags=["collaboration"])


@router.put("/members/{member_id}")
def upsert_member(
    member_id: str,
    value: WorkspaceMemberInput,
    context: RequestContext = Depends(require_context),
    service: CollaborationService = Depends(collaboration),
) -> dict[str, object]:
    if member_id != value.member_id:
        raise HTTPException(status_code=400, detail="member id mismatch")
    return service.upsert_member(context.workspace_id, value, int(time.time() * 1000))


@router.get("/members")
def list_members(
    context: RequestContext = Depends(require_context),
    service: CollaborationService = Depends(collaboration),
) -> list[dict[str, object]]:
    return service.list_members(context.workspace_id)


@router.put("/annotations/{annotation_id}")
def upsert_annotation(
    annotation_id: str,
    value: AnnotationInput,
    context: RequestContext = Depends(require_context),
    service: CollaborationService = Depends(collaboration),
) -> dict[str, object]:
    if annotation_id != value.id:
        raise HTTPException(status_code=400, detail="annotation id mismatch")
    try:
        return service.upsert_annotation(context.workspace_id, value)
    except ValueError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@router.get("/annotations/{item_id}")
def list_annotations(
    item_id: str,
    context: RequestContext = Depends(require_context),
    service: CollaborationService = Depends(collaboration),
) -> list[dict[str, object]]:
    return service.list_annotations(context.workspace_id, item_id)
