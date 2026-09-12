import hashlib
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException

from .config import Settings
from .db import Database


def reserve_enrichment_request(database: Database, settings: Settings, user_id: str) -> None:
    """Charge accepted attempts, including upstream failures, under one transaction."""
    now = datetime.now(UTC)
    day = now.date().isoformat()
    user_subject = hashlib.sha256(user_id.encode()).hexdigest()
    retry_after = int(
        (datetime.combine(now.date() + timedelta(days=1), datetime.min.time(), UTC) - now).total_seconds()
    )
    with database.connection() as connection:
        connection.execute("BEGIN IMMEDIATE")
        connection.execute(
            "DELETE FROM ai_enrichment_usage WHERE day < ?", ((now.date() - timedelta(days=14)).isoformat(),)
        )
        for subject, limit in [
            ("all", settings.ai_global_daily_limit),
            (user_subject, settings.ai_user_daily_limit),
        ]:
            row = connection.execute(
                "SELECT requests FROM ai_enrichment_usage WHERE day = ? AND subject = ?", (day, subject)
            ).fetchone()
            if row is not None and row["requests"] >= limit:
                raise HTTPException(
                    status_code=429,
                    detail="daily AI request limit reached",
                    headers={"Retry-After": str(max(1, retry_after))},
                )
            connection.execute(
                "INSERT INTO ai_enrichment_usage(day, subject, requests) VALUES(?, ?, 1) "
                "ON CONFLICT(day, subject) DO UPDATE SET requests = requests + 1",
                (day, subject),
            )
