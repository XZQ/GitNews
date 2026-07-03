import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../domain/trending_repository.dart';

/// 基于本地模拟数据的趋势仓库。
class LocalTrendingRepository implements TrendingRepository {
  const LocalTrendingRepository();

  @override
  Future<TrendingDigest> getDigest() async {
    return TrendingDigest(
      trendingRepos: DemoData.trending.map((e) => e.toEntity()).toList(),
      recentRepos: DemoData.recent.map((e) => e.toEntity()).toList(),
      languages: DemoData.languages.map((e) => e.toEntity()).toList(),
      primaryTrend: DemoData.generateStarTrend(38000, 4200),
      secondaryTrend: DemoData.generateStarTrend(35200, 3100),
      tertiaryTrend: DemoData.generateStarTrend(32000, 2800),
    );
  }
}
