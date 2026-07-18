import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/ai_news/data/ai_news_cache_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_library_filter.dart';

void main() {
  group('AiNewsCacheDao', () {
    late LocalDatabase db;
    late AiNewsCacheDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = AiNewsCacheDao(db.executor, CacheMetaDao(db.executor));
    });

    tearDown(() async => db.close());

    AiNewsItem makeItem(
      String id, {
      AiNewsCategory category = AiNewsCategory.aiModels,
      DateTime? publishedAt,
      String? title,
      String? summary,
      String source = 'src',
      String author = '',
      String content = '',
      String attributionSource = '',
    }) {
      return AiNewsItem(
        id: id,
        category: category,
        title: title ?? 'title $id',
        titleEn: 'title en $id',
        summary: summary ?? 'summary $id',
        source: source,
        url: 'https://example.com/$id',
        permalink: 'https://aihot.virxact.com/items/$id',
        publishedAt: publishedAt ?? DateTime.utc(2026, 6, 28),
        score: 70,
        selected: true,
        author: author,
        content: content,
        attributionSource: attributionSource,
      );
    }

    test('readAll should return empty list when no rows', () async {
      expect(await dao.readAll(), isEmpty);
    });

    test('upsertPage should persist items and meta', () async {
      final now = DateTime.utc(
        2026,
        6,
        30,
        10,
      );
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(items: [makeItem('a'), makeItem('b')], count: 2, hasNext: true, nextCursor: 'cur'),
        now: now,
      );

      final items = await dao.readAll();
      expect(items.length, 2);
      expect(items.map((e) => e.id).toSet(), {'a', 'b'});
    });

    test('readById should return a cached item by id', () async {
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(items: [makeItem('a'), makeItem('b')], count: 2, hasNext: false),
        now: DateTime.utc(2026, 6, 30, 10),
      );

      final item = await dao.readById('b');

      expect(item, isNotNull);
      expect(item?.id, 'b');
      expect(item?.title, 'title b');
    });

    test('RSS author, content and attribution survive the SQLite round-trip', () async {
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [makeItem('rss', author: 'Author', content: 'Content', attributionSource: 'AI HOT')],
          count: 1,
          hasNext: false,
        ),
        now: DateTime.utc(2026, 7, 19),
      );

      final item = await dao.readById('rss');

      expect(item?.author, 'Author');
      expect(item?.content, 'Content');
      expect(item?.attributionSource, 'AI HOT');
    });

    test('readById should return null when item is missing', () async {
      expect(await dao.readById('missing'), isNull);
    });

    test('isFresh should be false when meta missing', () async {
      expect(
          await dao.isFresh(
            category: null,
            cursor: null,
            ttl: const Duration(minutes: 5),
            now: DateTime.utc(2026, 6, 30, 10),
          ),
          isFalse);
    });

    test('isFresh should be true within TTL window', () async {
      final fetched = DateTime.utc(
        2026,
        6,
        30,
        10,
      );
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(items: [makeItem('a')], count: 1, hasNext: false),
        now: fetched,
      );

      expect(
          await dao.isFresh(
            category: null,
            cursor: null,
            ttl: const Duration(minutes: 5),
            now: fetched.add(const Duration(minutes: 3)),
          ),
          isTrue);
      expect(
          await dao.isFresh(
            category: null,
            cursor: null,
            ttl: const Duration(minutes: 5),
            now: fetched.add(const Duration(hours: 1, minutes: 1)),
          ),
          isFalse);
    });

    test('readAll should filter by category', () async {
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [makeItem('a', category: AiNewsCategory.aiModels), makeItem('b', category: AiNewsCategory.paper), makeItem('c', category: AiNewsCategory.aiModels)],
          count: 3,
          hasNext: false,
        ),
        now: DateTime.utc(
          2026,
          6,
          30,
          10,
        ),
      );

      final onlyAiModels = await dao.readAll(category: AiNewsCategory.aiModels);
      expect(onlyAiModels.length, 2);
      expect(onlyAiModels.every((e) => e.category == AiNewsCategory.aiModels), isTrue);
    });

    test('upsertPage should replace existing item by id', () async {
      final first = DateTime.utc(
        2026,
        6,
        30,
        10,
      );
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(items: [makeItem('a')], count: 1, hasNext: false),
        now: first,
      );

      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [
            AiNewsItem(
              id: 'a',
              category: AiNewsCategory.aiModels,
              title: 'updated title',
              titleEn: 'title en a',
              summary: 'summary a',
              source: 'src',
              url: 'https://example.com/a',
              permalink: 'https://aihot.virxact.com/items/a',
              publishedAt: DateTime.utc(2026, 6, 28),
              score: 90,
              selected: false,
            )
          ],
          count: 1,
          hasNext: false,
        ),
        now: first.add(const Duration(minutes: 10)),
      );

      final items = await dao.readAll();
      expect(items.length, 1);
      expect(items.first.title, 'updated title');
      expect(items.first.score, 90);
      expect(items.first.selected, isFalse);
    });

    test('clear should remove only ai_news_item rows', () async {
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(items: [makeItem('a')], count: 1, hasNext: false),
        now: DateTime.utc(2026, 6, 30, 10),
      );
      await dao.clear();
      expect(await dao.readAll(), isEmpty);
    });

    test('FTS5 search follows insert and replace updates', () async {
      final now = DateTime.utc(2026, 7, 16);
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [makeItem('a', title: 'Quantum model benchmark')],
          count: 1,
          hasNext: false,
        ),
        now: now,
      );
      expect((await dao.searchAll('quantum')).single.id, 'a');

      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [makeItem('a', title: 'Vision model benchmark')],
          count: 1,
          hasNext: false,
        ),
        now: now,
      );

      expect(await dao.searchAll('quantum'), isEmpty);
      expect((await dao.searchAll('vision')).single.id, 'a');
    });

    test('library search filters source, time and read state', () async {
      final now = DateTime.utc(2026, 7, 16);
      await dao.upsertPage(
        category: null,
        cursor: null,
        digest: AiNewsDigest(
          items: [
            makeItem(
              'new',
              title: 'Agent release',
              source: 'OpenAI',
              publishedAt: now,
            ),
            makeItem(
              'old',
              title: 'Agent archive',
              source: 'Other',
              publishedAt: now.subtract(const Duration(days: 60)),
            ),
          ],
          count: 2,
          hasNext: false,
        ),
        now: now,
      );
      await db.executor.insert('ai_news_state', {
        'item_id': 'new',
        'read_at': now.millisecondsSinceEpoch,
        'category': 'ai-models',
        'title': 'Agent release',
        'title_en': '',
        'summary': '',
        'source': 'OpenAI',
        'url': '',
        'permalink': '',
        'published_at': now.millisecondsSinceEpoch,
        'score': 0,
        'selected': 0,
        'updated_at': now.millisecondsSinceEpoch,
      });

      final results = await dao.searchAll(
        'agent',
        filter: AiNewsLibraryFilter(
          source: 'OpenAI',
          publishedAfter: now.subtract(const Duration(days: 7)),
          read: AiNewsReadFilter.read,
        ),
      );
      expect(results.map((item) => item.id), ['new']);
    });
  });
}
