import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ai_hot/ai_hot_api_support.dart';
import '../../../core/ai_hot/ai_hot_resource_cache.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/preferences/ai_news_source_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/aggregated_ai_news_repository.dart';
import '../data/ai_news_api_client.dart';
import '../data/ai_news_cache_dao.dart';
import '../data/ai_news_rss_client.dart';
import '../data/ai_news_state_dao.dart';
import '../data/remote_ai_hot_repository.dart';
import '../data/remote_ai_news_repository.dart';
import '../domain/ai_hot_daily.dart';
import '../domain/ai_hot_repository.dart';
import '../domain/ai_hot_status.dart';
import '../domain/ai_hot_topic.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';
import 'ai_news_example_items.dart';

export 'ai_news_items_notifier.dart';

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

// 资讯详情读取:详情页只依赖本地数据,避免再次请求远端或打开不稳定外站。
// 优先条目缓存;缓存被清理后回退稍后读的实体快照(ai_news_state)。
final aiNewsItemDetailProvider = FutureProvider.autoDispose.family<AiNewsItem?, String>((ref, id) async {
  final stateDao = AiNewsStateDao(ref.watch(appDatabaseProvider).executor);
  final cached = await ref.watch(aiNewsCacheDaoProvider).readById(id);
  if (cached != null) {
    return cached;
  }
  return await stateDao.snapshotOf(id) ?? aiNewsExampleItemById(id);
});

// 详情页相关推荐只读取本机缓存,不因打开详情额外请求远端。
final aiNewsRelatedItemsProvider = FutureProvider.autoDispose.family<List<AiNewsItem>, String>((ref, id) async {
  final cacheDao = ref.watch(aiNewsCacheDaoProvider);
  final current = await ref.watch(aiNewsItemDetailProvider(id).future);
  if (current == null) {
    return const [];
  }
  final items = await cacheDao.readAll();
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

/// Oldest validation time covering the complete current head query.
final aiNewsLastValidatedAtProvider = StateProvider<DateTime?>((ref) => null);
