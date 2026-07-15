import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/trending_repository.dart';
import 'trending_cache_dao.dart';
import 'trending_data_source.dart';

/* 
*带 SQLite TTL 缓存的趋势数据源包装器。
*/
class CachedTrendingDataSource implements TrendingDataSource, FreshnessTrendingDataSource {
  const CachedTrendingDataSource(
      {required this.remote, required this.cache, required this.now, this.cacheScope = 'anonymous', this.ttl = CacheTtlConfig.trending, this.isRateLimited, this.onRateLimited});

  final TrendingDataSource remote;
  final TrendingCacheDao cache;
  final String cacheScope;
  final DateTime Function() now;
  final Duration ttl;
  final bool Function()? isRateLimited;
  final void Function(int retryAfterSeconds)? onRateLimited;

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    return (await fetchTrendingResult(query)).data;
  }

  @override
  Future<DataResult<TrendingDataSnapshot>> fetchTrendingResult(TrendingQuery query) async {
    final current = now();
    final cached = await cache.readSnapshot(query, scope: cacheScope);
    final fresh = await cache.isFresh(query: query, scope: cacheScope, ttl: ttl, now: current);
    if (cached != null && fresh) {
      return DataResult(data: cached, freshness: DataFreshness.freshCache);
    }
    if (isRateLimited != null && isRateLimited!()) {
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      return DataResult(data: await remote.fetchTrending(query), freshness: DataFreshness.live);
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
      rethrow;
    }
  }
}
