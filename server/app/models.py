from __future__ import annotations

import json
from typing import Annotated, Any, Literal

from pydantic import AfterValidator, BaseModel, Field, field_validator

from .gharchive_hour import normalize_hour

# Bound stored payload sizes: sync records are small preference/entity snapshots,
# push events fan out to every subscription and must not amplify unbounded blobs.
# The push ceiling stays generous because ingestion batches up to 20 feed items
# whose RSS summaries are not truncated.
_MAX_SYNC_PAYLOAD_BYTES = 64 * 1024
_MAX_PUSH_PAYLOAD_BYTES = 1024 * 1024


def _check_payload_size(value: dict[str, Any], limit: int) -> dict[str, Any]:
    size = len(json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
    if size > limit:
        raise ValueError(f"payload exceeds {limit} bytes")
    return value


GhArchiveHour = Annotated[
    str,
    Field(pattern=r"^\d{4}-\d{2}-\d{2}-\d{1,2}$"),
    AfterValidator(normalize_hour),
]


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

    # Enforce the size ceiling on the push request only: SyncRecord (pull /
    # conflict output) inherits SyncRecordInput, and legacy rows written before
    # this limit must remain readable.
    @field_validator("records")
    @classmethod
    def validate_record_payload_sizes(cls, value: list[SyncRecordInput]) -> list[SyncRecordInput]:
        for record in value:
            _check_payload_size(record.payload, _MAX_SYNC_PAYLOAD_BYTES)
        return value


class SyncRecord(SyncRecordInput):
    workspace_id: str
    revision: int
    cursor: str


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
    endpoint: str = Field(max_length=2000)
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

    @field_validator("payload")
    @classmethod
    def validate_payload_size(cls, value: dict[str, Any]) -> dict[str, Any]:
        return _check_payload_size(value, _MAX_PUSH_PAYLOAD_BYTES)


class GhArchiveIngestRequest(BaseModel):
    hour: GhArchiveHour


class GhArchiveTrend(BaseModel):
    repo: str
    event_count: int
    unique_actors: int


class HealthResponse(BaseModel):
    status: Literal["ok"]
    database: dict[str, Any]
    scheduler_enabled: bool
