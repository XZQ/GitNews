from __future__ import annotations

import gzip
import json
import tempfile
import time
from collections import defaultdict
from collections.abc import Iterable
from typing import Any, BinaryIO

import httpx

from .db import Database
from .gharchive_hour import archive_filename_hour, normalize_hour
from .models import GhArchiveTrend

# Legacy databases stored GH Archive's unpadded filename hour. Normalize at
# query time so existing rows remain readable without rewriting their keys.
_NORMALIZED_HOUR_SQL = "substr(hour,1,11) || printf('%02d',CAST(substr(hour,12) AS INTEGER))"


class GhArchiveService:
    def __init__(self, database: Database, timeout_seconds: float = 30) -> None:
        self.database = database
        self.timeout_seconds = timeout_seconds

    async def download_and_ingest(self, hour: str) -> int:
        hour = normalize_hour(hour)
        url = f"https://data.gharchive.org/{archive_filename_hour(hour)}.json.gz"
        with tempfile.SpooledTemporaryFile(max_size=64 * 1024 * 1024) as buffer:
            async with httpx.AsyncClient(timeout=self.timeout_seconds, follow_redirects=True) as client:
                async with client.stream("GET", url) as response:
                    response.raise_for_status()
                    async for chunk in response.aiter_bytes():
                        buffer.write(chunk)
            buffer.seek(0)
            return self.ingest_gzip(hour, buffer)

    def ingest_gzip(self, hour: str, payload: BinaryIO) -> int:
        with gzip.GzipFile(fileobj=payload, mode="rb") as stream:
            events = (json.loads(line) for line in stream if line.strip())
            return self.ingest_events(hour, events)

    def ingest_events(self, hour: str, events: Iterable[dict[str, Any]]) -> int:
        hour = normalize_hour(hour)
        counts: dict[tuple[str, str], int] = defaultdict(int)
        actors: dict[tuple[str, str], set[str]] = defaultdict(set)
        processed = 0
        for event in events:
            repo = (event.get("repo") or {}).get("name")
            event_type = event.get("type")
            if not isinstance(repo, str) or not isinstance(event_type, str):
                continue
            key = (repo.lower(), event_type)
            counts[key] += 1
            actor = (event.get("actor") or {}).get("login")
            if isinstance(actor, str) and len(actors[key]) < 100_000:
                actors[key].add(actor.lower())
            processed += 1
        now = int(time.time() * 1000)
        with self.database.connection() as connection:
            connection.execute(f"DELETE FROM gharchive_stats WHERE {_NORMALIZED_HOUR_SQL}=?", (hour,))
            for (repo, event_type), event_count in counts.items():
                connection.execute(
                    """
                    INSERT INTO gharchive_stats(
                      hour,repo,event_type,event_count,unique_actors,updated_at
                    ) VALUES(?,?,?,?,?,?)
                    """,
                    (hour, repo, event_type, event_count, len(actors[(repo, event_type)]), now),
                )
        return processed

    def trends(
        self,
        *,
        since_hour: str,
        event_type: str | None,
        limit: int,
    ) -> list[GhArchiveTrend]:
        clauses = [f"({_NORMALIZED_HOUR_SQL}) >= ?"]
        args: list[object] = [normalize_hour(since_hour)]
        if event_type:
            clauses.append("event_type = ?")
            args.append(event_type)
        with self.database.connection() as connection:
            rows = connection.execute(
                f"""
                WITH canonical AS (
                  SELECT *, {_NORMALIZED_HOUR_SQL} AS canonical_hour
                  FROM gharchive_stats WHERE {" AND ".join(clauses)}
                ), latest AS (
                  SELECT *, ROW_NUMBER() OVER(
                    PARTITION BY canonical_hour,repo,event_type ORDER BY updated_at DESC,hour DESC
                  ) AS occurrence
                  FROM canonical
                )
                SELECT repo,SUM(event_count) AS event_count,SUM(unique_actors) AS unique_actors
                FROM latest WHERE occurrence=1
                GROUP BY repo ORDER BY event_count DESC,repo LIMIT ?
                """,
                [*args, limit],
            ).fetchall()
        return [GhArchiveTrend(**dict(row)) for row in rows]
