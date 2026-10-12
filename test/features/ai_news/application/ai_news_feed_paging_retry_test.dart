import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_cache_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_repository.dart';

/*
*控制分页失败、停滞游标和异步分类切换，保留真实 notifier 与缓存写入。
*/
class _PagedRepository implements AiNewsRepository {
  // 记录重试是否使用相同游标。
  final List<String?> cursors = [];

  // 下一页的可恢复网络失败。
  bool failNext = false;

  // 缓存耗尽后的 head 游标恢复请求也可能失败。
  bool failHead = false;

  // 模拟服务端成功返回但游标未推进。
  bool repeatCursor = false;

  // 分类切换时仍在进行的旧分页请求。
  Completer<DataResult<AiNewsDigest>>? pending;

  @override
  /* 首屏给出十条，后续页可以失败、等待或结束。 */
  Future<DataResult<AiNewsDigest>> fetchItems({AiNewsCategory? category, DateTime? since, String? query, String? cursor, bool selectedOnly = true, bool force = false}) async {
    cursors.add(cursor);
    if (category == AiNewsCategory.paper) {
      return const DataResult(
        data: AiNewsDigest(items: [], count: 0, hasNext: false),
        freshness: DataFreshness.live,
      );
    }
    if (cursor == null) {
      if (failHead) {
        throw StateError('simulated head failure');
      }
      return DataResult(
        data: AiNewsDigest(items: [for (var index = 0; index < 10; index++) _item(index)], count: 10, hasNext: true, nextCursor: 'next'),
        freshness: DataFreshness.live,
      );
    }
    if (pending != null) {
      return pending!.future;
    }
    if (failNext) {
      failNext = false;
      throw StateError('simulated next-page failure');
    }
    return DataResult(
      data: AiNewsDigest(items: repeatCursor ? [] : [_item(10)], count: repeatCursor ? 0 : 1, hasNext: repeatCursor, nextCursor: repeatCursor ? cursor : null),
      freshness: DataFreshness.live,
    );
  }
}

/*
*模拟分页内容和失败状态两次写入都失败，检查游标与错误仍可恢复。
*/
class _FailingCacheDao extends AiNewsCacheDao {
  _FailingCacheDao(LocalDatabase db) : super(db.executor, CacheMetaDao(db.executor));

  // 下一页内容持久化失败开关。
  bool failPageWrite = false;

  // 失败标记自身写入失败开关。
  bool failFailureStatus = false;

  @override
  /* 保留首屏正常写入，仅在测试指定时让分页保存失败。 */
  Future<void> upsertPage({required AiNewsCategory? category, required String? cursor, required AiNewsDigest digest, required DateTime now, bool validated = true}) async {
    if (failPageWrite && cursor != null) {
      throw StateError('simulated page write failure');
    }
    await super.upsertPage(category: category, cursor: cursor, digest: digest, now: now, validated: validated);
  }

  @override
  /* 二次持久化失败也不能从界面回调泄漏未处理 Future。 */
  Future<void> markValidationFailed({AiNewsCategory? category, String? cursor}) async {
    if (failFailureStatus) {
      throw StateError('simulated failure-status write failure');
    }
    await super.markValidationFailed(category: category, cursor: cursor);
  }
}

/* 验证翻页失败保留阅读内容与可重试游标。 */
void main() {
  late LocalDatabase db;
  late ProviderContainer container;
  late _PagedRepository repository;
  late _FailingCacheDao dao;
  setUp(() async {
    db = await LocalDatabase.openInMemory();
    repository = _PagedRepository();
    dao = _FailingCacheDao(db);
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        aiNewsCacheDaoProvider.overrideWithValue(dao),
        aiNewsRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 12, 12)),
      ],
    );
    container.listen(aiNewsItemsNotifierProvider, (_, _) {});
    await container.read(aiNewsItemsNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('failed next page preserves items and retries the same cursor successfully', () async {
    final notifier = container.read(aiNewsItemsNotifierProvider.notifier);
    repository.failNext = true;
    await notifier.loadMore();
    expect(container.read(aiNewsItemsNotifierProvider).value!.map((item) => item.id), [for (var index = 0; index < 10; index++) '$index']);
    expect(notifier.hasMore, isTrue);
    expect(notifier.loadMoreError, isNotNull);

    await notifier.loadMore();
    expect(repository.cursors, [null, 'next', 'next']);
    expect(container.read(aiNewsItemsNotifierProvider).value!.map((item) => item.id), [for (var index = 0; index < 11; index++) '$index']);
    expect(notifier.hasMore, isFalse);
    expect(notifier.loadMoreError, isNull);
  });

  test('successful page with an unchanged cursor still terminates without a retry error', () async {
    final notifier = container.read(aiNewsItemsNotifierProvider.notifier);
    repository.repeatCursor = true;
    await notifier.loadMore();
    expect(repository.cursors, [null, 'next']);
    expect(container.read(aiNewsItemsNotifierProvider).value, hasLength(10));
    expect(notifier.hasMore, isFalse);
    expect(notifier.loadMoreError, isNull);
  });

  test('cache write failure does not advance the cursor or leak failure-status errors', () async {
    final notifier = container.read(aiNewsItemsNotifierProvider.notifier);
    dao.failPageWrite = true;
    dao.failFailureStatus = true;
    await notifier.loadMore();
    expect(container.read(aiNewsItemsNotifierProvider).value, hasLength(10));
    expect(notifier.hasMore, isTrue);
    expect(notifier.loadMoreError, isNotNull);

    dao.failPageWrite = false;
    dao.failFailureStatus = false;
    await notifier.loadMore();
    expect(repository.cursors, [null, 'next', 'next']);
    expect(container.read(aiNewsItemsNotifierProvider).value, hasLength(11));
    expect(notifier.hasMore, isFalse);
    expect(notifier.loadMoreError, isNull);
  });

  test('cached query with no saved cursor also exposes and recovers from a paging error', () async {
    container.invalidate(aiNewsItemsNotifierProvider);
    await container.pump();
    await container.read(aiNewsItemsNotifierProvider.future);
    final notifier = container.read(aiNewsItemsNotifierProvider.notifier);
    repository.failHead = true;
    await notifier.loadMore();
    expect(notifier.hasMore, isTrue);
    expect(notifier.loadMoreError, isNotNull);
    expect(container.read(aiNewsItemsNotifierProvider).value, hasLength(10));

    repository.failHead = false;
    await notifier.loadMore();
    expect(repository.cursors, [null, null, null, 'next']);
    expect(container.read(aiNewsItemsNotifierProvider).value, hasLength(11));
    expect(notifier.loadMoreError, isNull);
    expect(notifier.hasMore, isFalse);
  });

  test('a delayed page cannot change the new category or its paging state', () async {
    final notifier = container.read(aiNewsItemsNotifierProvider.notifier);
    repository.pending = Completer<DataResult<AiNewsDigest>>();
    final paging = notifier.loadMore();
    container.read(aiNewsCategoryFilterProvider.notifier).state = AiNewsCategory.paper;
    await container.pump();
    expect(await container.read(aiNewsItemsNotifierProvider.future), isEmpty);
    repository.pending!.complete(
      DataResult(
        data: AiNewsDigest(items: [_item(10)], count: 1, hasNext: true, nextCursor: 'later'),
        freshness: DataFreshness.live,
      ),
    );
    await paging;
    expect(container.read(aiNewsItemsNotifierProvider).value, isEmpty);
    expect(notifier.hasMore, isFalse);
    expect(notifier.loadMoreError, isNull);
  });
}

/* 每条标题独立，避免分页回归被展示聚类干扰。 */
AiNewsItem _item(int index) => AiNewsItem(
  id: '$index',
  category: AiNewsCategory.aiModels,
  title: 'Independent model $index',
  titleEn: '',
  summary: '',
  source: 'Source',
  url: 'https://example.com/$index',
  permalink: '',
  publishedAt: DateTime.utc(2026, 10, 12, 12),
  score: 0,
  selected: true,
);
