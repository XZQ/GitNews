import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/data/ai_news_merge.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

AiNewsItem item(String id, {String title = '', String titleEn = '', String url = '', DateTime? publishedAt}) {
  return AiNewsItem(
    id: id,
    category: AiNewsCategory.industry,
    title: title,
    titleEn: titleEn,
    summary: '',
    source: 'src',
    url: url,
    permalink: url,
    publishedAt: publishedAt ?? DateTime.utc(2026, 7, 14),
    score: 0,
    selected: false,
  );
}

void main() {
  group('normalizeAiNewsUrl', () {
    test('strips tracking params, fragment and trailing slash', () {
      expect(normalizeAiNewsUrl('https://Example.com/Path/?utm_source=x&ref=y&a=1#frag'), 'https://example.com/Path?a=1');
    });

    test('keeps meaningful query params', () {
      expect(normalizeAiNewsUrl('https://example.com/p?id=42'), 'https://example.com/p?id=42');
    });
  });

  group('normalizeAiNewsTitle', () {
    test('lowercases and keeps alphanumerics and CJK', () {
      expect(normalizeAiNewsTitle('GPT-5 发布: Hello, World!'), 'gpt5发布helloworld');
    });

    test('too-short titles do not participate in dedup', () {
      expect(normalizeAiNewsTitle('GPT-5!'), '');
    });
  });

  group('mergeAiNewsItems', () {
    test('primary wins over rss duplicates by url', () {
      final primary = [item('p1', title: '主源标题一二三四', url: 'https://example.com/a?utm_source=feed')];
      final rss = [
        item(
          'r1',
          titleEn: 'Different Title Here',
          url: 'https://example.com/a/',
        ),
        item(
          'r2',
          titleEn: 'Unique RSS Item Here',
          url: 'https://example.com/b',
        )
      ];
      final merged = mergeAiNewsItems(primary: primary, extras: [rss]);
      expect(merged.map((e) => e.id), containsAll(['p1', 'r2']));
      expect(merged.map((e) => e.id), isNot(contains('r1')));
    });

    test('dedups by normalized title across sources', () {
      final primary = [item('p1', titleEn: 'OpenAI Releases GPT-5', url: 'https://a.com/1')];
      final rss = [item('r1', titleEn: 'OpenAI releases GPT-5!', url: 'https://b.com/2')];
      final merged = mergeAiNewsItems(primary: primary, extras: [rss]);
      expect(merged, hasLength(1));
      expect(merged.single.id, 'p1');
    });

    test('sorts by publishedAt desc', () {
      final merged = mergeAiNewsItems(
        primary: [
          item(
            'old',
            titleEn: 'Old Item Title Here',
            url: 'https://a.com/old',
            publishedAt: DateTime.utc(2026, 7, 10),
          )
        ],
        extras: [
          [
            item(
              'new',
              titleEn: 'New Item Title Here',
              url: 'https://a.com/new',
              publishedAt: DateTime.utc(2026, 7, 14),
            )
          ]
        ],
      );
      expect(merged.map((e) => e.id).toList(), ['new', 'old']);
    });
  });
}
