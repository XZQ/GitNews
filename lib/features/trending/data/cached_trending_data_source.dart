import '../../../core/config/cache_ttl_config.dart';
import '../domain/trending_repository.dart';
import 'trending_cache_dao.dart';
import 'trending_data_source.dart';

/// 带 SQLite TTL 缓存的趋势数据源包装器。
class CachedTrendingDataSource implements TrendingDataSource {
  const CachedTrendingDataSource({
    required this.remote,
    required this.cache,
    required this.now,
    this.cacheScope = 'anonymous',
    this.ttl = CacheTtlConfig.trending,
  });

  final TrendingDataSource remote;
  final TrendingCacheDao cache;
  final String cacheScope;
  final DateTime Function() now;
  final Duration ttl;

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    final current = now();
    final cached = await cache.readSnapshot(query, scope: cacheScope);
    final fresh = await cache.isFresh(
      query: query,
      scope: cacheScope,
      ttl: ttl,
      now: current,
    );
    if (cached != null && fresh) return cached;

    try {
      final snapshot = await remote.fetchTrending(query);
      await cache.upsertSnapshot(
        query: query,
        scope: cacheScope,
        snapshot: snapshot,
        now: now(),
      );
      return snapshot;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }
}
