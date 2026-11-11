import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/trending_repository.dart';
import 'local_trending_data_source.dart';
import 'trending_cache_dao.dart';
import 'trending_data_source.dart';

/* 
*带 SQLite TTL 缓存的趋势数据源包装器。
*/
class CachedTrendingDataSource implements TrendingDataSource, FreshnessTrendingDataSource {
  CachedTrendingDataSource({required this.remote, required this.cache, required this.now, this.cacheScope = 'anonymous', this.ttl = CacheTtlConfig.trending, this.isRateLimited, this.onRateLimited});

  final TrendingDataSource remote;
  final TrendingCacheDao cache;
  final String cacheScope;
  final DateTime Function() now;
  final Duration ttl;
  final bool Function()? isRateLimited;
  final void Function(int retryAfterSeconds)? onRateLimited;

  // 同键并发合并:冷启动时多个 provider 同时 miss 缓存,
  // 只发一次远端请求,避免重复查询竞写同一快照。
  final Map<String, Future<DataResult<TrendingDataSnapshot>>> _inFlight = {};

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query, {bool force = false}) async {
    return (await fetchTrendingResult(query, force: force)).data;
  }

  @override
  Future<DataResult<TrendingDataSnapshot>> fetchTrendingResult(TrendingQuery query, {bool force = false}) {
    final key = TrendingCacheDao.cacheKey(query, scope: cacheScope);
    final existing = _inFlight[key];
    if (existing != null && !force) {
      return existing;
    }
    // 块体返回 void:表达式体会把移除的 Future 返回给 whenComplete 等待,
    // 形成「等自己完成」的死锁。
    final future = _fetch(query, force: force).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<DataResult<TrendingDataSnapshot>> _fetch(TrendingQuery query, {required bool force}) async {
    final current = now();
    TrendingDataSnapshot? cached;
    var fresh = false;
    try {
      cached = await cache.readSnapshot(query, scope: cacheScope);
      fresh = await cache.isFresh(query: query, scope: cacheScope, ttl: ttl, now: current);
    } on AppException catch (e) {
      // 坏缓存行删除后按无缓存处理:一条损坏 payload 不能让热榜永久报错。
      AppLogger.warn('trendingCacheRead', meta: {'error': e.kind.name});
      try {
        await cache.deleteSnapshot(query, scope: cacheScope);
      } catch (_) {
        // 删除失败不阻断远端重试。
      }
      cached = null;
    }
    // force 只跳过新鲜度检查,不预删缓存:远端失败时仍回退过期缓存。
    if (cached != null && fresh && !force) {
      return DataResult(data: cached, freshness: DataFreshness.freshCache);
    }
    if (isRateLimited != null && isRateLimited!()) {
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      // 限流中且无任何缓存:与其它仓库一致,回退种子数据并明确标注口径,
      // 绝不继续消耗已受限的 GitHub 配额,也不把失败伪装成实时远端数据。
      return DataResult(data: await const LocalTrendingDataSource().fetchTrending(query), freshness: DataFreshness.seed);
    }

    try {
      final snapshot = await remote.fetchTrending(query);
      await cache.upsertSnapshot(query: query, scope: cacheScope, snapshot: snapshot, now: now());
      return DataResult(data: snapshot, freshness: DataFreshness.live);
    } catch (e) {
      if (e is AppException && e.kind == AppExceptionKind.rateLimit && onRateLimited != null) {
        onRateLimited!(e.retryAfterSeconds ?? 60);
      }
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      // 远端失败且无缓存:与限流分支一致回退种子并标注,不向上抛裸错误。
      AppLogger.warn('trendingRemoteFallback', meta: {'error': e.runtimeType.toString()});
      return DataResult(data: await const LocalTrendingDataSource().fetchTrending(query), freshness: DataFreshness.seed);
    }
  }
}
