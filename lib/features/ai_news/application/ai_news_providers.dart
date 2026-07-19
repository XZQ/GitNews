import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ai_hot/ai_hot_api_support.dart';
import '../../../core/ai_hot/ai_hot_resource_cache.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/preferences/ai_news_source_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/aggregated_ai_news_repository.dart';
import '../data/ai_news_api_client.dart';
import '../data/ai_news_cache_dao.dart';
import '../data/ai_news_rss_client.dart';
import '../data/ai_news_seed_data.dart';
import '../data/ai_news_state_dao.dart';
import '../data/remote_ai_hot_repository.dart';
import '../data/remote_ai_news_repository.dart';
import '../domain/ai_hot_daily.dart';
import '../domain/ai_hot_repository.dart';
import '../domain/ai_hot_status.dart';
import '../domain/ai_hot_topic.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';

// AI 资讯专用 dio 工厂:keyed by `baseUrl`,允许在测试中按需 override。
// 例如测试可通过
// `aiNewsDioProvider(AiNewsApiClient.baseUrl).overrideWithValue(mockDio)`
// 注入带 mock adapter 的 Dio。
final aiNewsDioProvider = Provider.family<Dio, String>(
  (ref, baseUrl) => DioClient.create(baseUrl: baseUrl, headers: const {'Accept': AiHotApiSupport.jsonAccept, 'User-Agent': AiHotApiSupport.userAgent}),
);

final aiHotResourceCacheProvider = Provider<AiHotResourceCache>(
  (ref) => AiHotResourceCache(dio: ref.watch(aiNewsDioProvider(AiNewsApiClient.baseUrl)), cache: ref.watch(jsonSnapshotCacheDaoProvider), now: ref.watch(clockProvider)),
);

final aiNewsApiClientProvider = Provider<AiNewsApiClient>((ref) => AiNewsApiClient(ref.watch(aiHotResourceCacheProvider)));

// 补充 RSS/Atom 源共享一个 Dio:feed URL 是绝对地址,baseUrl 不参与拼接;
// 走同一 keyed 工厂便于测试按 URL override。
final aiNewsRssClientProvider = Provider<AiNewsRssClient>((ref) => AiNewsRssClient(ref.watch(aiHotResourceCacheProvider)));

// 聚合仓库:主源(精选流)+ 补充 RSS 源,head 页去重合并。
// 任一源失败都不影响其余源;全部失败才抛错走缓存/种子降级。
final aiNewsRepositoryProvider = Provider<AiNewsRepository>((ref) {
  final sources = ref.watch(aiNewsSourceControllerProvider);
  final controller = ref.read(aiNewsSourceControllerProvider.notifier);
  return AggregatedAiNewsRepository(
    RemoteAiNewsRepository(ref.watch(aiNewsApiClientProvider)),
    ref.watch(aiNewsRssClientProvider),
    sources: sources.enabledConfigs,
    clock: ref.watch(clockProvider),
    onSourceSuccess: (id, at) => controller.reportSuccess(id, at),
    onSourceFailure: (id, at, error) => controller.reportFailure(id, at, error),
  );
});

// AI HOT 热点、日报、指纹与版本仓库。
final aiHotRepositoryProvider = Provider<AiHotRepository>((ref) => RemoteAiHotRepository(ref.watch(aiNewsApiClientProvider)));

// 当前多信源热点;失败不阻断主资讯流。
final aiHotTopicsProvider = FutureProvider.autoDispose<DataResult<List<AiHotTopic>>>((ref) => ref.watch(aiHotRepositoryProvider).fetchHotTopics());

// 最新 AI HOT 官方日报。
final aiHotLatestDailyProvider = FutureProvider.autoDispose<DataResult<AiHotDailyReport>>((ref) => ref.watch(aiHotRepositoryProvider).fetchLatestDaily());

// 最近 30 期日报索引。
final aiHotDailyIndexProvider = FutureProvider.autoDispose<DataResult<List<AiHotDailyEntry>>>((ref) => ref.watch(aiHotRepositoryProvider).fetchDailies());

// 指定日期官方日报。
final aiHotDailyProvider = FutureProvider.autoDispose.family<DataResult<AiHotDailyReport>, String>((ref, date) => ref.watch(aiHotRepositoryProvider).fetchDaily(date));

// AI HOT API/Skill 版本,长 TTL 且不影响内容加载。
final aiHotVersionProvider = FutureProvider.autoDispose<DataResult<AiHotVersion>>((ref) => ref.watch(aiHotRepositoryProvider).fetchVersion());

// AI 资讯缓存 DAO。共享全局 [appDatabaseProvider] 的 executor。
final aiNewsCacheDaoProvider = Provider<AiNewsCacheDao>((ref) => AiNewsCacheDao(ref.watch(appDatabaseProvider).executor, ref.watch(cacheMetaDaoProvider)));

// 时钟抽象,便于测试注入固定时刻。
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// 分类筛选:`null` 表示全部分类。
final aiNewsCategoryFilterProvider = StateProvider<AiNewsCategory?>((ref) => null);

// 顶部搜索框关键词。空字符串表示不过滤当前列表。
final aiNewsSearchQueryProvider = StateProvider<String>((ref) => '');

/* 
*基于当前已加载列表做本地搜索过滤。
*AI 动态当前仍由远端精选流 + 本地缓存驱动,搜索只过滤客户端已有条目,
*避免每次输入都打到第三方接口。
*/
List<AiNewsItem> filterAiNewsItems(List<AiNewsItem> items, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return items;
  }

  return [
    for (final item in items)
      if (_aiNewsSearchText(item).contains(keyword)) item,
  ];
}

String _aiNewsSearchText(AiNewsItem item) {
  return [item.title, item.titleEn, item.summary, item.source, item.category.label, item.category.code].join(' ').toLowerCase();
}

// 单次向用户暴露的条目数(分页步长)。
const int aiNewsPageSize = 10;

// 触底预加载阈值:剩余滚动距离(px)低于此值时立即拉取下一页。
// 单卡约 168px,3 条约 504px;取整 520 留一点提前量。
const double aiNewsLoadMoreScrollPixels = 520;

// 缓存 TTL:同一份查询(category + cursor=head)在此时长内不再发远端请求。
const Duration aiNewsCacheTtl = CacheTtlConfig.aiNews;

// 条目列表(分页 + 触底加载 + 本地缓存优先)。
// 加载流程(两阶段):
// 1. **Phase A(立即可渲染)**:从 [AiNewsCacheDao] 读缓存,有数据立即
// `state = AsyncData(...)`,UI 不出现骨架屏
// 2. **Phase B(后台静默)**:若 cache_meta 判定已过期(或从未拉取),
// 静默发起远端请求;成功后刷新 buffer + state + DB;失败保持现状
// 切换分类会触发 [ref.watch] 重建 → 状态自动重置。
final aiNewsItemsNotifierProvider = AsyncNotifierProvider.autoDispose<AiNewsItemsNotifier, List<AiNewsItem>>(AiNewsItemsNotifier.new);

// 资讯详情读取:详情页只依赖本地数据,避免再次请求远端或打开不稳定外站。
// 优先条目缓存;缓存被清理后回退稍后读的实体快照(ai_news_state)。
final aiNewsItemDetailProvider = FutureProvider.autoDispose.family<AiNewsItem?, String>((ref, id) async {
  final cached = await ref.watch(aiNewsCacheDaoProvider).readById(id);
  if (cached != null) {
    return cached;
  }
  return AiNewsStateDao(ref.watch(appDatabaseProvider).executor).snapshotOf(id);
});

// 详情页相关推荐只读取本机缓存,不因打开详情额外请求远端。
final aiNewsRelatedItemsProvider = FutureProvider.autoDispose.family<List<AiNewsItem>, String>((ref, id) async {
  final current = await ref.watch(aiNewsItemDetailProvider(id).future);
  if (current == null) {
    return const [];
  }
  final items = await ref.watch(aiNewsCacheDaoProvider).readAll();
  return selectRelatedAiNewsItems(items, current: current);
});

/* 按同分类、热度和发布时间选择详情页相关推荐。 */
List<AiNewsItem> selectRelatedAiNewsItems(List<AiNewsItem> items, {required AiNewsItem current, int limit = 3}) {
  final candidates = items.where((item) => item.id != current.id).toList();
  candidates.sort((left, right) {
    final leftCategoryRank = left.category == current.category ? 0 : 1;
    final rightCategoryRank = right.category == current.category ? 0 : 1;
    final categoryComparison = leftCategoryRank.compareTo(rightCategoryRank);
    if (categoryComparison != 0) {
      return categoryComparison;
    }
    final scoreComparison = right.score.compareTo(left.score);
    if (scoreComparison != 0) {
      return scoreComparison;
    }
    return right.publishedAt.compareTo(left.publishedAt);
  });
  return candidates.take(limit).toList(growable: false);
}

// 当前资讯流的数据来源口径(live/freshCache/staleCache/seed)。
// 由 [AiNewsItemsNotifier] 在关键决策点写入,供页头与首页预览展示 badge,
// 让用户清楚当前看到的是实时、缓存还是种子兜底数据。
final aiNewsFreshnessProvider = StateProvider<DataFreshness>((ref) => DataFreshness.live);

class AiNewsItemsNotifier extends AsyncNotifier<List<AiNewsItem>> {
  List<AiNewsItem> _buffer = const [];
  String? _nextCursor;
  bool _hasApiMore = true;
  // 仅用于阻止「同 cursor 的并发请求」,不阻塞 loadMore 从已有 buffer 切片。
  bool _fetching = false;
  AiNewsCategory? _category;
  // 代际令牌:每次 build 自增,用于让未完成的旧请求在 resolve 后识别「我已被新分类覆盖」。
  int _generation = 0;

  @override
  Future<List<AiNewsItem>> build() async {
    _generation++;
    final gen = _generation;
    _category = ref.watch(aiNewsCategoryFilterProvider);
    _buffer = const [];
    _nextCursor = null;
    _hasApiMore = true;
    _fetching = false;

    final dao = ref.read(aiNewsCacheDaoProvider);
    final now = ref.read(clockProvider)();
    final freshness = ref.read(aiNewsFreshnessProvider.notifier);

    // Phase A:优先读缓存,瞬间出列表
    final cached = await dao.readAll(category: _category);
    if (!ref.mounted || gen != _generation) {
      return const [];
    }
    if (cached.isNotEmpty) {
      _buffer = cached;
      // 缓存里没有分页游标信息;乐观认为远端可能还有更多,
      // 让 loadMore 在 buffer 耗尽时尝试拉远端(走 head 刷新路径)
      _hasApiMore = true;
      state = AsyncData(_currentSlice());
    }

    // Phase B:缓存仍新鲜就不发请求,否则后台静默刷新
    final fresh = await dao.isFresh(category: _category, cursor: null, ttl: aiNewsCacheTtl, now: now);
    if (!ref.mounted || gen != _generation) {
      return const [];
    }
    if (fresh) {
      // 缓存命中且未过期:无需远端
      freshness.state = DataFreshness.freshCache;
      return _currentSlice();
    }

    await _fetchNextPage(generation: gen);
    if (!ref.mounted || gen != _generation) {
      return const [];
    }
    return _currentSlice();
  }

  /* 
  *触底加载:优先从已缓冲数据切片;缓冲区不足且未在请求中时,再请求下一页。
  *设计要点:不依赖 build() 是否完成,只要 buffer 里有数据就能增量展示;
  *当需要请求新 cursor 页时,通过 [Future] 同步步队,避免与 build 阶段的
  *初次请求或后续预取请求打架。
  */
  Future<void> loadMore() async {
    if (state.hasError) {
      return;
    }
    final shown = state.value?.length ?? 0;
    if (shown < _buffer.length) {
      final nextEnd = (shown + aiNewsPageSize).clamp(0, _buffer.length);
      if (nextEnd > shown) {
        state = AsyncData(_buffer.sublist(0, nextEnd));
      }
      return;
    }
    if (_fetching) {
      return;
    }
    while (_hasApiMore && (state.value?.length ?? 0) >= _buffer.length) {
      final previousCursor = _nextCursor;
      final previousBufferLength = _buffer.length;
      await _fetchNextPage();
      if (!ref.mounted) {
        return;
      }
      if (_buffer.length > previousBufferLength || !_hasApiMore) {
        break;
      }
      if (_nextCursor == previousCursor) {
        _hasApiMore = false;
        break;
      }
    }
    final newShown = state.value?.length ?? 0;
    final nextEnd = (newShown + aiNewsPageSize).clamp(0, _buffer.length);
    if (nextEnd > newShown) {
      state = AsyncData(_buffer.sublist(0, nextEnd));
    } else if (!_hasApiMore) {
      state = AsyncData(List<AiNewsItem>.of(state.value ?? const []));
    }
  }

  /* 
  *是否还有更多条目可加载(供 UI 决定是否显示底部 loader / 「没有更多」)。
  */
  bool get hasMore {
    final shown = state.value?.length ?? 0;
    return shown < _buffer.length || _hasApiMore;
  }

  List<AiNewsItem> _currentSlice() => _buffer.sublist(0, _buffer.length.clamp(0, aiNewsPageSize));

  Future<void> _fetchNextPage({int? generation}) async {
    final gen = generation ?? _generation;
    if (!ref.mounted || (_fetching && gen == _generation)) {
      return;
    }
    _fetching = true;
    final freshness = ref.read(aiNewsFreshnessProvider.notifier);
    // 关键不变量:cursor=null 表示「拉 head 页」(初始化或刷新),
    // 用新结果覆盖 buffer;cursor 非空表示「翻下一页」,追加到 buffer。
    final requestCursor = _nextCursor;
    final isHead = requestCursor == null;
    try {
      final result = await ref.read(aiNewsRepositoryProvider).fetchItems(category: _category, cursor: requestCursor, selectedOnly: true);
      final digest = result.data;
      if (!ref.mounted || gen != _generation) {
        return;
      }
      _buffer = _mergeUnique(isHead ? [...digest.items, ..._buffer] : [..._buffer, ...digest.items]);
      final nextCursor = digest.nextCursor?.trim();
      _nextCursor = nextCursor == null || nextCursor.isEmpty ? null : nextCursor;
      _hasApiMore = digest.hasNext && _nextCursor != null;
      freshness.state = result.freshness;
      // 落盘 + 更新 head meta。
      final dao = ref.read(aiNewsCacheDaoProvider);
      final now = ref.read(clockProvider)();
      await dao.upsertPage(
        category: _category,
        // 分页按实际 cursor 落盘；新鲜度判断仍只读取 head 的 meta。
        cursor: requestCursor,
        digest: digest,
        now: now,
      );
    } catch (e) {
      if (!ref.mounted || gen != _generation) {
        return;
      }
      _fetching = false;
      // 后台刷新失败容忍:已有缓存数据就不报错,标记为陈旧缓存兜底
      if (state.value != null) {
        freshness.state = DataFreshness.staleCache;
        return;
      }
      // 没有任何缓存且远端不可用:回退到本地种子数据,保证首启可渲染。
      _buffer = AiNewsSeedData.items;
      freshness.state = DataFreshness.seed;
      state = AsyncData(_currentSlice());
    }
    if (gen == _generation) {
      _fetching = false;
    }
  }

  List<AiNewsItem> _mergeUnique(List<AiNewsItem> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) item,
    ];
  }
}
