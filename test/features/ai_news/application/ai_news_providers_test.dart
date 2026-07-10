import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_cache_dao.dart';
import 'package:github_news/features/ai_news/data/ai_news_seed_data.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_repository.dart';

class _MockAiNewsRepository implements AiNewsRepository {
  _MockAiNewsRepository(this._stub);

  final List<AiNewsItem> _stub;
  AiNewsCategory? lastCategoryArg;
  int callCount = 0;

  @override
  Future<DataResult<AiNewsDigest>> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) async {
    callCount++;
    lastCategoryArg = category;
    return DataResult(
      data: AiNewsDigest(
        items: _stub,
        count: _stub.length,
        hasNext: false,
      ),
      freshness: DataFreshness.live,
    );
  }
}

class _PagedAiNewsRepository implements AiNewsRepository {
  _PagedAiNewsRepository(this._pages);

  final Map<String?, AiNewsDigest> _pages;
  final List<String?> cursors = [];

  @override
  Future<DataResult<AiNewsDigest>> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) async {
    cursors.add(cursor);
    return DataResult(
      data: _pages[cursor] ?? const AiNewsDigest(items: [], count: 0, hasNext: false),
      freshness: DataFreshness.live,
    );
  }
}

AiNewsItem _item(
  String id, {
  AiNewsCategory category = AiNewsCategory.aiModels,
  String title = 't',
  String titleEn = 'te',
  String summary = '',
  String source = 's',
}) =>
    AiNewsItem(
      id: id,
      category: category,
      title: title,
      titleEn: titleEn,
      summary: summary,
      source: source,
      url: 'https://example.com/$id',
      permalink: 'https://aihot.virxact.com/items/$id',
      publishedAt: DateTime.utc(2026, 6, 28),
      score: 70,
      selected: true,
    );

/* 
*等待 provider 进入稳态(Phase A + Phase B 均完成)。
*Notifier 在 Phase A 通过 `state = AsyncData(cached)` 立即出缓存,
*这会让 `.future` 提前 resolve;此时 Phase B 可能仍在后台跑,
*而且 autoDispose 可能在没有 listener 时把 Notifier 实例销毁,
*导致 Phase B 的 state 更新被丢弃。
*本 helper 通过 [ProviderContainer.listen] 保持一个常驻订阅,
*让 Notifier 一直存活,然后给 Phase B 足够的 event-loop tick。
*/
Future<List<AiNewsItem>> _pumpUntilSettled(ProviderContainer container) async {
  final sub = container.listen(aiNewsItemsNotifierProvider, (prev, next) {});
  try {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return container.read(aiNewsItemsNotifierProvider).valueOrNull ?? const [];
  } finally {
    sub.close();
  }
}

void main() {
  late LocalDatabase db;
  late AiNewsCacheDao dao;

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    dao = AiNewsCacheDao(db.executor, CacheMetaDao(db.executor));
  });

  tearDown(() async => db.close());

  ProviderContainer makeContainer(
    AiNewsRepository repo, {
    DateTime Function()? clock,
  }) {
    final clk = clock ?? (() => DateTime.utc(2026, 6, 30, 10));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        aiNewsRepositoryProvider.overrideWithValue(repo),
        aiNewsCacheDaoProvider.overrideWithValue(dao),
        clockProvider.overrideWithValue(clk),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('首次加载:无缓存时必须发远端请求', () async {
    final repo = _MockAiNewsRepository([_item('a'), _item('b')]);
    final container = makeContainer(repo);

    final items = await container.read(aiNewsItemsNotifierProvider.future);

    expect(items.length, 2);
    expect(repo.callCount, 1);
  });

  test('缓存命中且未过期:不应发远端请求', () async {
    final now = DateTime.utc(2026, 6, 30, 10);
    // 第一次:预热缓存
    final repo1 = _MockAiNewsRepository([_item('a')]);
    final c1 = makeContainer(repo1, clock: () => now);
    await c1.read(aiNewsItemsNotifierProvider.future);
    expect(repo1.callCount, 1);

    // 第二次:3 分钟后,应命中缓存
    final repo2 = _MockAiNewsRepository([_item('a')]);
    final c2 = makeContainer(repo2, clock: () => now.add(const Duration(minutes: 3)));
    final items = await _pumpUntilSettled(c2);

    expect(items.length, 1);
    expect(repo2.callCount, 0); // 未触发远端
    expect(readFreshness(c2), DataFreshness.freshCache);
  });

  test('缓存过期:应在后台静默刷新', () async {
    final now = DateTime.utc(2026, 6, 30, 10);
    // 预热
    final repo1 = _MockAiNewsRepository([_item('a')]);
    final c1 = makeContainer(repo1, clock: () => now);
    await c1.read(aiNewsItemsNotifierProvider.future);
    expect(repo1.callCount, 1);

    // 6 分钟后,缓存过期
    final repo2 = _MockAiNewsRepository([_item('a'), _item('b')]);
    final c2 = makeContainer(repo2, clock: () => now.add(const Duration(minutes: 6)));
    final items = await _pumpUntilSettled(c2);

    expect(repo2.callCount, 1);
    expect(items.length, 2);
  });

  test('setting category filter should propagate code to the repository', () async {
    final repo = _MockAiNewsRepository([_item('a')]);
    final container = makeContainer(repo);

    container.read(aiNewsCategoryFilterProvider.notifier).state = AiNewsCategory.aiModels;
    await container.read(aiNewsItemsNotifierProvider.future);

    expect(repo.lastCategoryArg, AiNewsCategory.aiModels);
  });

  test('filterAiNewsItems should match loaded item fields locally', () {
    final items = [
      _item(
        'a',
        title: 'OpenAI 发布新模型',
        titleEn: 'OpenAI launches model',
        source: 'OpenAI Blog',
      ),
      _item(
        'b',
        category: AiNewsCategory.industry,
        summary: '融资与行业动态升温',
        source: '36氪',
      ),
    ];

    expect(filterAiNewsItems(items, '').length, 2);
    expect(filterAiNewsItems(items, 'openai'), [items.first]);
    expect(filterAiNewsItems(items, '融资'), [items.last]);
    expect(filterAiNewsItems(items, 'industry'), [items.last]);
    expect(filterAiNewsItems(items, 'missing'), isEmpty);
  });

  test('触底加载应使用 nextCursor 追加下一页', () async {
    final repo = _PagedAiNewsRepository({
      null: AiNewsDigest(
        items: [for (var i = 0; i < aiNewsPageSize; i++) _item('head_$i')],
        count: aiNewsPageSize,
        hasNext: true,
        nextCursor: 'cursor_2',
      ),
      'cursor_2': AiNewsDigest(
        items: [_item('next_1'), _item('next_2')],
        count: 2,
        hasNext: false,
      ),
    });
    final container = makeContainer(repo);
    final sub = container.listen(aiNewsItemsNotifierProvider, (prev, next) {});
    addTearDown(sub.close);

    final firstPage = await container.read(aiNewsItemsNotifierProvider.future);
    expect(firstPage, hasLength(aiNewsPageSize));

    await container.read(aiNewsItemsNotifierProvider.notifier).loadMore();

    final loaded = container.read(aiNewsItemsNotifierProvider).valueOrNull!;
    expect(loaded.map((e) => e.id).toList(), [
      for (var i = 0; i < aiNewsPageSize; i++) 'head_$i',
      'next_1',
      'next_2',
    ]);
    expect(repo.cursors, [null, 'cursor_2']);
    expect(container.read(aiNewsItemsNotifierProvider.notifier).hasMore, isFalse);
  });

  test('远端缺少 nextCursor 时不应无限显示底部加载', () async {
    final repo = _PagedAiNewsRepository({
      null: AiNewsDigest(
        items: [for (var i = 0; i < aiNewsPageSize; i++) _item('head_$i')],
        count: aiNewsPageSize,
        hasNext: true,
      ),
    });
    final container = makeContainer(repo);
    final sub = container.listen(aiNewsItemsNotifierProvider, (prev, next) {});
    addTearDown(sub.close);

    await container.read(aiNewsItemsNotifierProvider.future);
    await container.read(aiNewsItemsNotifierProvider.notifier).loadMore();

    expect(repo.cursors, [null]);
    expect(container.read(aiNewsItemsNotifierProvider.notifier).hasMore, isFalse);
  });

  test('无缓存且远端失败:应回退到种子数据并标记 seed', () async {
    final repo = _ThrowingAiNewsRepository();
    final container = makeContainer(repo);

    final items = await container.read(aiNewsItemsNotifierProvider.future);

    expect(items, isNotEmpty);
    expect(
      items.map((e) => e.id).toList(),
      AiNewsSeedData.items.map((e) => e.id).toList(),
    );
    expect(container.read(aiNewsFreshnessProvider), DataFreshness.seed);
  });

  test('缓存命中但远端失败:应保留缓存并标记陈旧缓存', () async {
    final now = DateTime.utc(2026, 6, 30, 10);
    // 预热
    final repo1 = _MockAiNewsRepository([_item('a')]);
    final c1 = makeContainer(repo1, clock: () => now);
    await c1.read(aiNewsItemsNotifierProvider.future);
    expect(repo1.callCount, 1);

    // 远端开始持续失败,但缓存仍存在(且已过期,会触发后台刷新)
    final repo2 = _ThrowingAiNewsRepository();
    final c2 = makeContainer(repo2, clock: () => now.add(const Duration(minutes: 10)));
    final items = await _pumpUntilSettled(c2);

    expect(items.map((e) => e.id).toList(), ['a']);
    expect(readFreshness(c2), DataFreshness.staleCache);
  });
}

DataFreshness readFreshness(ProviderContainer container) => container.read(aiNewsFreshnessProvider);

class _ThrowingAiNewsRepository implements AiNewsRepository {
  @override
  Future<DataResult<AiNewsDigest>> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) async {
    throw Exception('network unavailable');
  }
}
