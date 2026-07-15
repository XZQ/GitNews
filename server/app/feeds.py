from __future__ import annotations

import hashlib
import html
import re
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import UTC, datetime
from email.utils import parsedate_to_datetime

import httpx

from .db import Database
from .models import NewsItem


@dataclass(frozen=True, slots=True)
class FeedSource:
    id: str
    name: str
    url: str
    category: str


SOURCES = (
    FeedSource("openai_news", "OpenAI News", "https://openai.com/news/rss.xml", "ai-products"),
    FeedSource("huggingface_blog", "Hugging Face Blog", "https://huggingface.co/blog/feed.xml", "tip"),
    FeedSource("google_ai_blog", "Google AI Blog", "https://blog.google/technology/ai/rss/", "industry"),
    FeedSource("arxiv_cs_ai", "arXiv cs.AI", "https://rss.arxiv.org/rss/cs.AI", "paper"),
)


class FeedIngestor:
    def __init__(self, database: Database, timeout_seconds: float = 30) -> None:
        self.database = database
        self.timeout_seconds = timeout_seconds

    async def fetch_all(self) -> tuple[list[NewsItem], list[str]]:
        items: list[NewsItem] = []
        errors: list[str] = []
        async with httpx.AsyncClient(timeout=self.timeout_seconds, follow_redirects=True) as client:
            for source in SOURCES:
                try:
                    response = await client.get(source.url, headers={"User-Agent": "github-news-server/0.1"})
                    response.raise_for_status()
                    items.extend(parse_feed(response.content, source)[:50])
                except Exception as error:  # noqa: BLE001 - isolate each external source
                    errors.append(f"{source.id}:{type(error).__name__}")
        return _deduplicate(items), errors

    def persist(self, items: list[NewsItem]) -> list[NewsItem]:
        if not items:
            return []
        now = int(time.time() * 1000)
        with self.database.connection() as connection:
            existing = {
                row["id"]
                for row in connection.execute(
                    f"SELECT id FROM news_items WHERE id IN ({','.join('?' for _ in items)})",
                    [item.id for item in items],
                )
            }
            for item in items:
                content_hash = hashlib.sha256(
                    f"{item.title}\n{item.summary}\n{item.url}".encode()
                ).hexdigest()
                connection.execute(
                    """
                    INSERT INTO news_items(
                      id,title,summary,source,category,url,published_at,content_hash,updated_at
                    ) VALUES(?,?,?,?,?,?,?,?,?)
                    ON CONFLICT(id) DO UPDATE SET
                      title=excluded.title, summary=excluded.summary, source=excluded.source,
                      category=excluded.category, url=excluded.url,
                      published_at=excluded.published_at, content_hash=excluded.content_hash,
                      updated_at=excluded.updated_at
                    """,
                    (
                        item.id,
                        item.title,
                        item.summary,
                        item.source,
                        item.category,
                        item.url,
                        item.published_at,
                        content_hash,
                        now,
                    ),
                )
        return [item for item in items if item.id not in existing]

    def list_items(self, *, limit: int, source: str | None, since: int | None) -> list[NewsItem]:
        clauses: list[str] = []
        args: list[object] = []
        if source:
            clauses.append("source = ?")
            args.append(source)
        if since is not None:
            clauses.append("published_at >= ?")
            args.append(since)
        where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
        with self.database.connection() as connection:
            rows = connection.execute(
                f"SELECT id,title,summary,source,category,url,published_at FROM news_items "
                f"{where} ORDER BY published_at DESC LIMIT ?",
                [*args, limit],
            ).fetchall()
        return [NewsItem(**dict(row)) for row in rows]


def parse_feed(payload: bytes, source: FeedSource) -> list[NewsItem]:
    root = ET.fromstring(payload)
    nodes = root.findall(".//item")
    atom = False
    if not nodes:
        atom = True
        nodes = [node for node in root.iter() if _local_name(node.tag) == "entry"]
    return [_parse_node(node, source, atom=atom) for node in nodes]


def _parse_node(node: ET.Element, source: FeedSource, *, atom: bool) -> NewsItem:
    values = {_local_name(child.tag): child for child in node}
    title = _text(values.get("title")) or "Untitled"
    summary = _clean(_text(values.get("summary")) or _text(values.get("description")))
    link_node = values.get("link")
    url = (link_node.get("href") if atom and link_node is not None else _text(link_node)) or ""
    published = _text(values.get("published")) or _text(values.get("updated")) or _text(values.get("pubDate"))
    published_at = _parse_time(published)
    stable = url or f"{title}:{published_at}"
    item_id = hashlib.sha256(f"{source.id}:{stable}".encode()).hexdigest()[:32]
    return NewsItem(
        id=item_id,
        title=html.unescape(title.strip()),
        summary=summary,
        source=source.name,
        category=source.category,
        url=url.strip(),
        published_at=published_at,
    )


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _text(node: ET.Element | None) -> str:
    return "" if node is None else "".join(node.itertext()).strip()


def _clean(value: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", html.unescape(value))).strip()


def _parse_time(value: str) -> int:
    try:
        parsed = parsedate_to_datetime(value)
    except (TypeError, ValueError):
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            parsed = datetime.now(UTC)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=UTC)
    return int(parsed.timestamp() * 1000)


def _deduplicate(items: list[NewsItem]) -> list[NewsItem]:
    by_id = {item.id: item for item in items}
    return sorted(by_id.values(), key=lambda item: item.published_at, reverse=True)
