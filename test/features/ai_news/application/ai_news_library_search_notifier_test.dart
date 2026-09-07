import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_cache_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_library_filter.dart';

void main() {
  late LocalDatabase db;
  late _SearchDao dao;
  late ProviderContainer container;
  final provider = aiNewsLibrarySearchProvider('模型');

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    dao = _SearchDao(db);
    final items = [for (var index = 0; index < 121; index++) _item(index)];
    await dao.upsertPage(
      category: null,
      cursor: null,
      digest: AiNewsDigest(items: items, count: items.length, hasNext: false),
      now: DateTime.utc(2026, 7, 1),
    );
    container = ProviderContainer(overrides: [aiNewsCacheDaoProvider.overrideWithValue(dao)]);
    container.listen(provider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('all 121 Chinese matches are reachable with stable, non-overlapping pages', () async {
    expect((await container.read(provider.future)).items, hasLength(50));
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, hasLength(100));
    await container.read(provider.notifier).loadMore();
    final result = container.read(provider).value!;
    expect(result.items.map((item) => item.id), [for (var index = 0; index < 121; index++) '$index'.padLeft(3, '0')]);
    expect(result.hasMore, isFalse);
    expect(result.nextOffset, 121);
  });

  test('paging failure preserves results and the same page can be retried', () async {
    await container.read(provider.future);
    dao.failNext = true;
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, hasLength(50));
    expect(container.read(provider).value!.loadMoreError, isNotNull);
    await container.read(provider.notifier).loadMore();
    expect(container.read(provider).value!.items, hasLength(100));
    expect(container.read(provider).value!.loadMoreError, isNull);
  });

  test('filter change rejects an in-flight page from the previous category', () async {
    await container.read(provider.future);
    dao.pending = Completer<List<AiNewsItem>>();
    final paging = container.read(provider.notifier).loadMore();
    container.read(aiNewsCategoryFilterProvider.notifier).state = AiNewsCategory.paper;
    await container.pump();
    expect((await container.read(provider.future)).items, isEmpty);
    dao.pending!.complete([_item(50)]);
    await paging;
    expect(container.read(provider).value!.items, isEmpty);
    expect(container.read(provider).value!.hasMore, isFalse);
  });

  test('substring matching covers title, summary and source with literal symbols', () async {
    await dao.upsertPage(
      category: null,
      cursor: null,
      digest: AiNewsDigest(
        items: [_item(200, title: '报告', summary: '人工智能模型发布', source: '研究%所')],
        count: 1,
        hasNext: false,
      ),
      now: DateTime.utc(2026, 7, 1),
    );
    expect((await dao.searchAll('智能 模型', filter: const AiNewsLibraryFilter(source: '研究%所'))).single.id, '200');
    expect((await dao.searchAll('研究%')).single.id, '200');
    expect((await dao.searchAll('%')).single.id, '200');
    expect(await dao.searchAll('_'), isEmpty);
    expect(await dao.searchAll('模型 OR "'), isEmpty);
  });
}

class _SearchDao extends AiNewsCacheDao {
  _SearchDao(LocalDatabase db) : super(db.executor, CacheMetaDao(db.executor));
  bool failNext = false;
  Completer<List<AiNewsItem>>? pending;

  @override
  Future<List<AiNewsItem>> searchAll(String query, {AiNewsCategory? category, AiNewsLibraryFilter filter = const AiNewsLibraryFilter(), int limit = 100, int offset = 0}) {
    if (offset > 0 && failNext) {
      failNext = false;
      throw StateError('simulated cache failure');
    }
    if (offset > 0 && pending != null) return pending!.future;
    return super.searchAll(query, category: category, filter: filter, limit: limit, offset: offset);
  }
}

AiNewsItem _item(int index, {String? title, String summary = '', String source = 'source'}) => AiNewsItem(
  id: '$index'.padLeft(3, '0'),
  category: AiNewsCategory.aiModels,
  title: title ?? '人工智能模型发布 $index',
  titleEn: 'Model release $index',
  summary: summary,
  source: source,
  url: 'https://example.com/$index',
  permalink: '',
  publishedAt: DateTime.utc(2026, 7, 1),
  score: 70,
  selected: true,
);
