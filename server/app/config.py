from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Settings:
    database_path: Path
    master_key: str
    scheduler_enabled: bool
    ingest_interval_seconds: int
    push_interval_seconds: int
    request_timeout_seconds: float

    @classmethod
    def from_env(cls) -> Settings:
        return cls(
            database_path=Path(os.getenv("GITHUB_NEWS_DB", "data/github_news_server.db")),
            master_key=os.getenv("GITHUB_NEWS_MASTER_KEY", "change-me"),
            scheduler_enabled=_bool_env("GITHUB_NEWS_SCHEDULER_ENABLED", True),
            ingest_interval_seconds=max(60, int(os.getenv("GITHUB_NEWS_INGEST_INTERVAL", "900"))),
            push_interval_seconds=max(10, int(os.getenv("GITHUB_NEWS_PUSH_INTERVAL", "30"))),
            request_timeout_seconds=max(5, float(os.getenv("GITHUB_NEWS_REQUEST_TIMEOUT", "30"))),
        )


def _bool_env(key: str, default: bool) -> bool:
    value = os.getenv(key)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}
