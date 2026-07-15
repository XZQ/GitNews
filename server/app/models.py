from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator


class NewsItem(BaseModel):
    id: str
    title: str
    summary: str = ""
    source: str
    category: str
    url: str
    published_at: int


class IngestResult(BaseModel):
    run_id: str
    status: Literal["ok", "partial", "failed"]
    item_count: int
    errors: list[str] = Field(default_factory=list)


class SyncRecordInput(BaseModel):
    namespace: str = Field(min_length=1, max_length=80)
    record_id: str = Field(min_length=1, max_length=200)
    payload: dict[str, Any] = Field(default_factory=dict)
    version: int = Field(ge=1)
    deleted: bool = False
    updated_at: int = Field(gt=0)


class SyncPushRequest(BaseModel):
    records: list[SyncRecordInput] = Field(max_length=1000)


class SyncRecord(SyncRecordInput):
    workspace_id: str


class SyncPushResult(BaseModel):
    accepted: int
    conflicts: list[SyncRecord]


class WorkspaceMemberInput(BaseModel):
    member_id: str = Field(min_length=1, max_length=120)
    display_name: str = Field(min_length=1, max_length=120)
    role: Literal["owner", "editor", "viewer"] = "viewer"


class AnnotationInput(BaseModel):
    id: str = Field(min_length=1, max_length=120)
    item_id: str = Field(min_length=1, max_length=200)
    author_id: str = Field(min_length=1, max_length=120)
    body: str = Field(min_length=1, max_length=5000)
    version: int = Field(ge=1)
    updated_at: int = Field(gt=0)


class PushSubscriptionInput(BaseModel):
    id: str = Field(min_length=1, max_length=120)
    kind: Literal["webhook", "fcm", "apns", "wns"]
    endpoint: str
    secret: str | None = Field(default=None, max_length=500)

    @field_validator("endpoint")
    @classmethod
    def validate_endpoint(cls, value: str) -> str:
        text = value.strip()
        if not text:
            raise ValueError("endpoint is required")
        return text


class PushEventInput(BaseModel):
    event_type: str = Field(min_length=1, max_length=120)
    payload: dict[str, Any]


class GhArchiveIngestRequest(BaseModel):
    hour: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}-\d{1,2}$")


class GhArchiveTrend(BaseModel):
    repo: str
    event_count: int
    unique_actors: int


class HealthResponse(BaseModel):
    status: Literal["ok"]
    database: dict[str, Any]
    scheduler_enabled: bool
