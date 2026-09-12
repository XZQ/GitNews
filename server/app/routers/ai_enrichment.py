from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import ValidationError

from ..ai_enrichment_models import AI_ENRICHMENT_MAX_BODY, AiEnrichmentInput, AiEnrichmentResponse

router = APIRouter(prefix="/v1/ai", tags=["AI enrichment"])
_bearer = HTTPBearer(auto_error=False)


@router.post(
    "/enrichment",
    response_model=AiEnrichmentResponse,
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {"application/json": {"schema": AiEnrichmentInput.model_json_schema()}},
        }
    },
)
async def enrich(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> AiEnrichmentResponse:
    if credentials is None:
        raise HTTPException(status_code=401, detail="sign in required")
    # Bound streamed/chunked bodies too, before JSON allocation and validation.
    body = bytearray()
    async for chunk in request.stream():
        if len(body) + len(chunk) > AI_ENRICHMENT_MAX_BODY:
            raise HTTPException(status_code=413, detail="article too large")
        body.extend(chunk)
    try:
        article = AiEnrichmentInput.model_validate_json(body)
    except ValidationError:
        raise HTTPException(status_code=422, detail="invalid article fields") from None
    return await request.app.state.ai_enrichment.enrich(credentials.credentials, article)
