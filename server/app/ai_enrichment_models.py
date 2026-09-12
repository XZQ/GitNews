from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

AI_ENRICHMENT_MODEL = "agnes-2.0-flash"
AI_ENRICHMENT_MAX_BODY = 64 * 1024
EntityName = Annotated[str, Field(min_length=1, max_length=200)]


class AiEnrichmentInput(BaseModel):
    """Only article fields are accepted; callers cannot choose prompts or models."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    title: str = Field(min_length=1, max_length=512)
    title_en: str = Field(default="", max_length=512)
    summary: str = Field(default="", max_length=8000)
    source: str = Field(default="", max_length=128)
    url: str = Field(default="", max_length=2048)


class AiEnrichmentEntities(BaseModel):
    model_config = ConfigDict(extra="forbid")
    models: list[EntityName] = Field(default_factory=list, max_length=20)
    companies: list[EntityName] = Field(default_factory=list, max_length=20)
    repositories: list[EntityName] = Field(default_factory=list, max_length=20)


class AiEnrichmentContent(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    generated_summary: str = Field(min_length=1, max_length=512)
    translated_title: str = Field(min_length=1, max_length=1024)
    translated_summary: str = Field(min_length=1, max_length=12000)
    importance_score: float = Field(ge=0, le=100, allow_inf_nan=False)
    entities: AiEnrichmentEntities


class AiEnrichmentResponse(BaseModel):
    model: str = AI_ENRICHMENT_MODEL
    enrichment: AiEnrichmentContent
