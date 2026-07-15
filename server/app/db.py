from __future__ import annotations

import json
import sqlite3
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import Any


class Database:
    def __init__(self, path: Path) -> None:
        self.path = path

    def initialize(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connection() as connection:
            connection.executescript(_SCHEMA)

    @contextmanager
    def connection(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self.path, timeout=30)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("PRAGMA journal_mode = WAL")
        try:
            yield connection
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()

    def health(self) -> dict[str, Any]:
        with self.connection() as connection:
            row = connection.execute("SELECT sqlite_version() AS version").fetchone()
        return {"ok": True, "sqlite_version": row["version"], "path": str(self.path)}


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True)


def parse_json(value: str) -> Any:
    return json.loads(value)


_SCHEMA = """
CREATE TABLE IF NOT EXISTS news_items (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  source TEXT NOT NULL,
  category TEXT NOT NULL,
  url TEXT NOT NULL,
  published_at INTEGER NOT NULL,
  content_hash TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_news_published ON news_items(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_source ON news_items(source, published_at DESC);

CREATE TABLE IF NOT EXISTS sync_records (
  workspace_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  record_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  version INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(workspace_id, namespace, record_id)
);
CREATE INDEX IF NOT EXISTS idx_sync_updated ON sync_records(workspace_id, updated_at);

CREATE TABLE IF NOT EXISTS workspace_members (
  workspace_id TEXT NOT NULL,
  member_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(workspace_id, member_id)
);

CREATE TABLE IF NOT EXISTS annotations (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  item_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  body TEXT NOT NULL,
  version INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_annotations_item ON annotations(workspace_id, item_id, updated_at);

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  secret TEXT,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS push_outbox (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  status TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  delivered_at INTEGER,
  FOREIGN KEY(subscription_id) REFERENCES push_subscriptions(id)
);
CREATE INDEX IF NOT EXISTS idx_push_pending ON push_outbox(status, next_attempt_at);

CREATE TABLE IF NOT EXISTS gharchive_stats (
  hour TEXT NOT NULL,
  repo TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_count INTEGER NOT NULL,
  unique_actors INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(hour, repo, event_type)
);
CREATE INDEX IF NOT EXISTS idx_gharchive_repo ON gharchive_stats(repo, hour DESC);

CREATE TABLE IF NOT EXISTS ingest_runs (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  status TEXT NOT NULL,
  item_count INTEGER NOT NULL,
  detail TEXT,
  started_at INTEGER NOT NULL,
  finished_at INTEGER NOT NULL
);
"""
