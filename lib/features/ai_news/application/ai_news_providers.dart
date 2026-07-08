import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_provenance.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/ai_news_api_client.dart';
import '../data/ai_news_cache_dao.dart';
import '../data/ai_news_seed_data.dart';
import '../data/remote_ai_news_repository.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';

// AI 资讯专用 dio 工厂:keyed by `baseUrl`,允许在测试中按需 override。
// 例如测试可通过
// `aiNewsDioProvider(AiNewsApiClient.baseUrl).overrideWithValue(mockDio)`
// 注入带 mock adapter 的 Dio。
final aiNewsDioProvider = Provider.family<Dio, String>(
  (ref, baseUrl) => DioClient.create(
    baseUrl: baseUrl,
    headers: const {
      'Accept': 'application/json',
      'User-Agent': GitHubApiSupport.userAgent,
    },
  ),
);

final aiNewsApiClientProvider = Provider<AiNewsApiClient>(
  (ref) => AiNewsApiClient.create(
    ref.watch(aiNewsDioProvider(AiNewsApiClient.baseUrl)),
  ),
);

final aiNewsRepositoryProvider = Provider<AiNewsRepository>(
  (ref) => RemoteAiNewsRepository(ref.watch(aiNewsApiClientProvider)),
);

// AI 资讯缓存 DAO。共享全局 [appDatabaseProvider] 的 executor。
final aiNewsCacheDaoProvider = Provider<AiNewsCacheDao>(
  (ref) => AiNewsCacheDao(
    ref.watch(appDatabaseProvider).executor,
    ref.watch(cacheMetaDaoProvider),
  ),
);

// 时钟抽象,便于测试注入固定时刻。
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// 分类筛选:`null` 表示全部分类。
final aiNewsCategoryFilterProvider = StateProvider<AiNewsCategory?>(
  (ref) => null,
);

// 顶部搜索框关键词。空字符串表示不过滤当前列表。
final aiNewsSearchQueryProvider = StateProvider<String>((ref) => '');

/* 
*基于当前已加载列表做本地搜索过滤。
*AI 动态当前仍由远端精选流 + 本地缓存驱动,搜索只过滤客户端已有条目,
*避免每次输入都打到第三方接口。
*/
List<AiNewsItem> filterAiNewsItems(
  List<AiNewsItem> items,
  String query,
) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return items;

  return [
    for (final item in items)
      if (_aiNewsSearchText(item).contains(keyword)) item,
  ];
}

String _aiNewsSearchText(AiNewsItem item) {
  return [
    item.title,
    item.titleEn,
    item.summary,
    item.source,
    item.category.label,
    item.category.code,
  ].join(' ').toLowerCase();
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
final aiNewsItemsNotifierProvider =
    AsyncNotifierProvider.autoDispose<AiNewsItemsNotifier, List<AiNewsItem>>(
  AiNewsItemsNotifier.new,
);

// 资讯详情读取:详情页只依赖本地缓存,避免再次请求远端或打开不稳定外站。
final aiNewsItemDetailProvider =
    FutureProvider.autoDispose.family<AiNewsItem?, String>(
  (ref, id) => ref.watch(aiNewsCacheDaoProvider).readById(id),
);

// 当前资讯流的数据来源口径(live/freshCache/staleCache/seed)。
// 由 [AiNewsItemsNotifier] 在关键决策点写入,供页头与首页预览展示 badge,
// 让用户清楚当前看到的是实时、缓存还是种子兜底数据。
final aiNewsProvenanceProvider = StateProvider<DataProvenance>(
  (ref) => DataProvenance.live,
);

class AiNewsItemsNotifier extends AutoDisposeAsyncNotifier<List<AiNewsItem>> {
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
    final provenance = ref.read(aiNewsProvenanceProvider.notifier);

    // Phase A:优先读缓存,瞬间出列表
    final cached = await dao.readAll(category: _category);
    if (gen != _generation) return const [];
    if (cached.isNotEmpty) {
      _buffer = cached;
      // 缓存里没有分页游标信息;乐观认为远端可能还有更多,
      // 让 loadMore 在 buffer 耗尽时尝试拉远端(走 head 刷新路径)
      _hasApiMore = true;
      state = AsyncData(_currentSlice());
    }

    // Phase B:缓存仍新鲜就不发请求,否则后台静默刷新
    final fresh = await dao.isFresh(
      category: _category,
      cursor: null,
      ttl: aiNewsCacheTtl,
      now: now,
    );
    if (gen != _generation) return const [];
    if (fresh) {
      // 缓存命中且未过期:无需远端
      provenance.state = DataProvenance.freshCache;
      return _currentSlice();
    }

    await _fetchNextPage(generation: gen);
    if (gen != _generation) return const [];
    return _currentSlice();
  }

  /* 
  *触底加载:优先从已缓冲数据切片;缓冲区不足且未在请求中时,再请求下一页。
  *设计要点:不依赖 build() 是否完成,只要 buffer 里有数据就能增量展示;
  *当需要请求新 cursor 页时,通过 [Future] 同步步队,避免与 build 阶段的
  *初次请求或后续预取请求打架。
  */
  Future<void> loadMore() async {
    if (state.hasError) return;
    final shown = state.valueOrNull?.length ?? 0;
    if (shown < _buffer.length) {
      final nextEnd = (shown + aiNewsPageSize).clamp(0, _buffer.length);
      if (nextEnd > shown) {
        state = AsyncData(_buffer.sublist(0, nextEnd));
      }
      return;
    }
    if (!_hasApiMore) return;
    await _fetchNextPage();
    final newShown = state.valueOrNull?.length ?? 0;
    final nextEnd = (newShown + aiNewsPageSize).clamp(0, _buffer.length);
    if (nextEnd > newShown) {
      state = AsyncData(_buffer.sublist(0, nextEnd));
    }
  }

  /* 
  *是否还有更多条目可加载(供 UI 决定是否显示底部 loader / 「没有更多」)。
  */
  bool get hasMore {
    final shown = state.valueOrNull?.length ?? 0;
    return shown < _buffer.length || _hasApiMore;
  }

  List<AiNewsItem> _currentSlice() =>
      _buffer.sublist(0, _buffer.length.clamp(0, aiNewsPageSize));

  Future<void> _fetchNextPage({int? generation}) async {
    final gen = generation ?? _generation;
    if (_fetching && gen == _generation) return;
    _fetching = true;
    final provenance = ref.read(aiNewsProvenanceProvider.notifier);
    // 关键不变量:cursor=null 表示「拉 head 页」(初始化或刷新),
    // 用新结果覆盖 buffer;cursor 非空表示「翻下一页」,追加到 buffer。
    final isHead = _nextCursor == null;
    try {
      final digest = await ref.read(aiNewsRepositoryProvider).fetchItems(
            category: _category,
            cursor: _nextCursor,
          );
      if (gen != _generation) return;
      _buffer = isHead ? digest.items : [..._buffer, ...digest.items];
      _nextCursor = digest.nextCursor;
      _hasApiMore = digest.hasNext;
      provenance.state = DataProvenance.live;
      // 落盘 + 更新 head meta。
      final dao = ref.read(aiNewsCacheDaoProvider);
      final now = ref.read(clockProvider)();
      await dao.upsertPage(
        category: _category,
        // meta 始终对齐 head 查询,因为我们只对 head 做 TTL 判定
        cursor: null,
        digest: digest,
        now: now,
      );
    } catch (e) {
      if (gen != _generation) return;
      _fetching = false;
      // 后台刷新失败容忍:已有缓存数据就不报错,标记为陈旧缓存兜底
      if (state.valueOrNull != null) {
        provenance.state = DataProvenance.staleCache;
        return;
      }
      // 没有任何缓存且远端不可用:回退到本地种子数据,保证首启可渲染。
      _buffer = AiNewsSeedData.items;
      provenance.state = DataProvenance.seed;
      state = AsyncData(_currentSlice());
    }
    if (gen == _generation) _fetching = false;
  }
}
