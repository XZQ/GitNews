from __future__ import annotations

import asyncio
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import Database
from app.feeds import FeedIngestor


async def main() -> int:
    with tempfile.TemporaryDirectory() as directory:
        database = Database(Path(directory) / "feed-smoke.db")
        database.initialize()
        ingestor = FeedIngestor(database, timeout_seconds=15)
        items, errors = await ingestor.fetch_all()
        if not items:
            raise RuntimeError(f"all live feeds failed: {', '.join(errors) or 'no items'}")
        ingestor.persist(items)
        stored = ingestor.list_items(limit=500, source=None, since=None)
        if len(stored) != len(items):
            raise RuntimeError(f"feed persistence mismatch: fetched={len(items)} stored={len(stored)}")
        sources = sorted({item.source for item in items})
        print(
            "Live feed smoke passed: "
            f"items={len(items)} sources={','.join(sources)} "
            f"isolated_errors={','.join(errors) or 'none'}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
