from app.db import Database
from app.feeds import FeedIngestor, FeedSource, parse_feed


def test_parse_rss_and_persist_deduplicates(settings):
    source = FeedSource("example", "Example", "https://example.com/feed", "industry")
    payload = b"""
    <rss><channel><item>
      <title>AI release</title>
      <description><![CDATA[<p>Important update</p>]]></description>
      <link>https://example.com/release</link>
      <pubDate>Wed, 16 Jul 2026 01:00:00 GMT</pubDate>
    </item></channel></rss>
    """
    items = parse_feed(payload, source)
    assert len(items) == 1
    assert items[0].summary == "Important update"

    database = Database(settings.database_path)
    database.initialize()
    ingestor = FeedIngestor(database)
    assert len(ingestor.persist(items)) == 1
    assert ingestor.persist(items) == []
    assert ingestor.list_items(limit=10, source="Example", since=None)[0].title == "AI release"
