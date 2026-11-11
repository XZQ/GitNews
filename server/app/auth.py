from __future__ import annotations

import secrets
from dataclasses import dataclass

from fastapi import Depends, Header, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .config import Settings


@dataclass(frozen=True, slots=True)
class RequestContext:
    workspace_id: str


_bearer = HTTPBearer(auto_error=False)


def get_settings(request: Request) -> Settings:
    return request.app.state.settings


def require_context(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    workspace_id: str = Header(default="personal", alias="X-Workspace-ID"),
    settings: Settings = Depends(get_settings),
) -> RequestContext:
    # Compare bytes: compare_digest on str raises TypeError for non-ASCII
    # input, which a crafted Authorization header could turn into a 500.
    if credentials is None or not secrets.compare_digest(
        credentials.credentials.encode("utf-8"), settings.master_key.encode("utf-8")
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid bearer token",
        )
    normalized = workspace_id.strip()
    if not normalized or len(normalized) > 120:
        raise HTTPException(status_code=400, detail="invalid workspace id")
    return RequestContext(workspace_id=normalized)
