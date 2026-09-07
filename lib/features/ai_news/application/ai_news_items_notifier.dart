import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../data/ai_news_seed_data.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_providers.dart';

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

/*
*资讯条目分页加载器:两阶段缓存优先 + 触底增量。
*
*代际令牌 [_generation] 让未完成的旧请求在 resolve 后识别「我已被新分类
*  覆盖」, [_fetching] 仅阻止同 cursor 并发请求,不阻塞 buffer 切片。
*/
class AiNewsItemsNotifier extends AsyncNotifier<List<AiNewsItem>> {
  List<AiNewsItem> _buffer = const [];
  String? _nextCursor;
  bool _hasApiMore = true;
  // 仅用于阻止「同 cursor 的并发请求」,不阻塞 loadMore 从已有 buffer 切片。
  bool _fetching = false;
  AiNewsCategory? _category;
  // 代际令牌:每次 build 自增,用于让未完成的旧请求在 resolve 后识别「我已被新分类覆盖」。
  int _generation = 0;

  bool _forceNextBuild = false;
  Future<List<AiNewsItem>>? _pendingLoad;
  Future<void>? _refreshTask;

  @override
  Future<List<AiNewsItem>> build() {
    final force = _forceNextBuild;
    _forceNextBuild = false;
    return _pendingLoad = _load(force: force);
  }

  /// Rebuilds this query and waits for revalidation even if cached rows render early.
  Future<void> refresh() => _refreshTask ??= _refreshHead().whenComplete(() => _refreshTask = null);

  Future<void> _refreshHead() async {
    _forceNextBuild = true;
    ref.invalidateSelf();
    await future;
    await _pendingLoad;
  }

  Future<List<AiNewsItem>> _load({required bool force}) async {
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
    if (fresh && !force) {
      // 缓存命中且未过期:无需远端
      freshness.state = DataFreshness.freshCache;
      return _currentSlice();
    }

    await _fetchNextPage(generation: gen, force: force);
    if (!ref.mounted || gen != _generation) {
      return const [];
    }
    return _currentSlice();
  }

  /*
  *触底加载:优先从已缓冲数据切片;缓冲区不足且未在请求中时,再请求下一页。
  *
  *设计要点:不依赖 build() 是否完成,只要 buffer 里有数据就能增量展示;
  *  当需要请求新 cursor 页时,通过 [Future] 同步步队,避免与 build 阶段的
  *  初次请求或后续预取请求打架。
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

  Future<void> _fetchNextPage({int? generation, bool force = false}) async {
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
      final result = await ref.read(aiNewsRepositoryProvider).fetchItems(category: _category, cursor: requestCursor, selectedOnly: true, force: force);
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
