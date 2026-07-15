import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/ai_news_sources_config.dart';
import 'package:github_news/features/ai_news/data/ai_news_feed_parser.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  const source = AiNewsSourceConfig(id: 'test_src', name: 'Test Source', feedUrl: 'https://example.com/feed.xml', categoryCode: 'paper');
  final fallback = DateTime.utc(2026, 7, 14, 12);

  group('parseAiNewsFeed / RSS 2.0', () {
    const rss = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Feed</title>
    <pubDate>Mon, 13 Jul 2026 08:00:00 GMT</pubDate>
    <item>
      <title>Hello &amp; World</title>
      <link>https://example.com/a</link>
      <description>&lt;p&gt;Some &lt;b&gt;bold&lt;/b&gt; text&lt;/p&gt;</description>
      <pubDate>Mon, 13 Jul 2026 10:30:00 -0400</pubDate>
    </item>
    <item>
      <title>No date item</title>
      <link>https://example.com/b</link>
      <description>plain</description>
    </item>
    <item>
      <title>No link, skipped</title>
      <description>x</description>
    </item>
  </channel>
</rss>
''';

    test('maps items to AiNewsItem with source defaults', () {
      final items = parseAiNewsFeed(rss, source: source, fallbackTime: fallback);
      expect(items, hasLength(2));
      final first = items.first;
      expect(first.id, startsWith('rss:test_src:'));
      expect(first.category, AiNewsCategory.paper);
      expect(first.title, 'Hello & World');
      expect(first.summary, 'Some bold text');
      expect(first.source, 'Test Source');
      expect(first.url, 'https://example.com/a');
      // -0400 → UTC。
      expect(first.publishedAt, DateTime.utc(2026, 7, 13, 14, 30));
    });

    test('item without date falls back to channel date', () {
      final items = parseAiNewsFeed(rss, source: source, fallbackTime: fallback);
      expect(items[1].publishedAt, DateTime.utc(2026, 7, 13, 8));
    });

    test('same link yields stable id across parses', () {
      final a = parseAiNewsFeed(rss, source: source, fallbackTime: fallback);
      final b = parseAiNewsFeed(rss, source: source, fallbackTime: fallback);
      expect(a.first.id, b.first.id);
    });
  });

  group('parseAiNewsFeed / Atom', () {
    const atom = '''
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <entry>
    <title>Atom Entry</title>
    <link rel="alternate" href="https://example.com/atom-1"/>
    <link rel="self" href="https://example.com/self"/>
    <summary>summary text</summary>
    <published>2026-07-12T09:00:00Z</published>
  </entry>
</feed>
''';

    test('maps entries with alternate link and ISO date', () {
      final items = parseAiNewsFeed(atom, source: source, fallbackTime: fallback);
      expect(items, hasLength(1));
      expect(items.first.url, 'https://example.com/atom-1');
      expect(items.first.publishedAt, DateTime.utc(2026, 7, 12, 9));
    });
  });

  group('parseRfc822Date', () {
    test('parses numeric offset', () {
      expect(parseRfc822Date('Sat, 18 Apr 2026 00:00:00 -0400'), DateTime.utc(2026, 4, 18, 4));
    });

    test('treats GMT as UTC and returns null on garbage', () {
      expect(parseRfc822Date('Mon, 13 Jul 2026 08:00:00 GMT'), DateTime.utc(2026, 7, 13, 8));
      expect(parseRfc822Date('not a date'), isNull);
    });
  });

  test('invalid xml throws AppException(parse)', () {
    expect(() => parseAiNewsFeed('<not-xml', source: source, fallbackTime: fallback), throwsA(isA<Exception>()));
  });
}
