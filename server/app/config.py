from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

# Placeholder values shipped in .env.example / docs; copying them verbatim
# must not produce a running server with a publicly known key.
_PLACEHOLDER_MASTER_KEYS = {"change-me", "replace-with-a-long-random-secret"}
_MIN_MASTER_KEY_LENGTH = 16


@dataclass(frozen=True, slots=True)
class Settings:
    database_path: Path
    master_key: str
    scheduler_enabled: bool
    ingest_interval_seconds: int
    push_interval_seconds: int
    request_timeout_seconds: float
    ai_enrichment_key: str = field(default="", repr=False)
    supabase_url: str = ""
    supabase_publishable_key: str = field(default="", repr=False)
    ai_user_daily_limit: int = 20
    ai_global_daily_limit: int = 500
    webhook_allow_private: bool = False
    cors_origins: list[str] = field(default_factory=lambda: ["*"])

    @classmethod
    def from_env(cls) -> Settings:
        # Fail fast: a missing or default master key would leave every
        # authenticated endpoint effectively open. Docker compose already
        # enforces this via `${...:?}`; this guards bare `uvicorn` runs.
        master_key = os.getenv("GITHUB_NEWS_MASTER_KEY", "").strip()
        if (
            not master_key
            or master_key in _PLACEHOLDER_MASTER_KEYS
            or len(master_key) < _MIN_MASTER_KEY_LENGTH
        ):
            raise RuntimeError(
                "GITHUB_NEWS_MASTER_KEY must be set to a non-default secret of at least "
                f"{_MIN_MASTER_KEY_LENGTH} characters before starting the server"
            )
        return cls(
            database_path=Path(os.getenv("GITHUB_NEWS_DB", "data/github_news_server.db")),
            master_key=master_key,
            scheduler_enabled=_bool_env("GITHUB_NEWS_SCHEDULER_ENABLED", True),
            ingest_interval_seconds=max(60, int(os.getenv("GITHUB_NEWS_INGEST_INTERVAL", "900"))),
            push_interval_seconds=max(10, int(os.getenv("GITHUB_NEWS_PUSH_INTERVAL", "30"))),
            request_timeout_seconds=max(5, float(os.getenv("GITHUB_NEWS_REQUEST_TIMEOUT", "30"))),
            ai_enrichment_key=os.getenv("AI_ENRICHMENT_AGNES_API_KEY", "").strip(),
            supabase_url=os.getenv("SUPABASE_URL", "").strip().rstrip("/"),
            supabase_publishable_key=os.getenv("SUPABASE_PUBLISHABLE_KEY", "").strip(),
            ai_user_daily_limit=max(1, int(os.getenv("AI_ENRICHMENT_USER_DAILY_LIMIT", "20"))),
            ai_global_daily_limit=max(1, int(os.getenv("AI_ENRICHMENT_GLOBAL_DAILY_LIMIT", "500"))),
            webhook_allow_private=_bool_env("GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE", False),
            cors_origins=_origins_env("GITHUB_NEWS_CORS_ORIGINS"),
        )


def _bool_env(key: str, default: bool) -> bool:
    value = os.getenv(key)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _origins_env(key: str) -> list[str]:
    # Comma-separated browser origin allowlist; unset keeps the permissive
    # default for non-browser (desktop/mobile) clients that ignore CORS.
    value = os.getenv(key, "").strip()
    if not value:
        return ["*"]
    return [origin.strip() for origin in value.split(",") if origin.strip()]
