import '../../../core/domain/data_freshness.dart';
import '../domain/entities.dart';
import '../domain/trending_repository.dart';

/* 
*趋势数据源快照。
*真实数据接入时,GitHub REST / GraphQL / GH Archive 先归一化到本结构,
*再由 Repository 转成页面使用的 [TrendingDigest]。
*/
class TrendingDataSnapshot {
  const TrendingDataSnapshot({
    required this.trendingRepos,
    required this.recentRepos,
    required this.languages,
    required this.primaryTrend,
    required this.secondaryTrend,
    required this.tertiaryTrend,
    this.topics = const [],
  });

  final List<RepoEntity> trendingRepos;
  final List<RepoEntity> recentRepos;
  final List<LanguageEntity> languages;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;
  final List<double> tertiaryTrend;

  // 当前搜索结果中聚合的高频 GitHub topics。
  final List<TrendingTopicEntity> topics;
}

/* 
*趋势数据源抽象。
*/
abstract interface class TrendingDataSource {
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query);
}

abstract interface class FreshnessTrendingDataSource {
  Future<DataResult<TrendingDataSnapshot>> fetchTrendingResult(TrendingQuery query);
}
