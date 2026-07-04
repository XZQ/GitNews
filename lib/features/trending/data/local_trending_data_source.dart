import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../domain/entities.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/// 基于内置种子数据的趋势数据源。
///
/// 保持与真实远端数据源相同的边界:先按查询条件取数,再交给 Repository
/// 组装页面 digest。
class LocalTrendingDataSource implements TrendingDataSource {
  const LocalTrendingDataSource();

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    final trendingRepos = DemoData.trending.map((e) => e.toEntity()).toList();
    final recentRepos = DemoData.recent.map((e) => e.toEntity()).toList();

    return TrendingDataSnapshot(
      trendingRepos: _filterRepos(trendingRepos, query),
      recentRepos: _filterRepos(recentRepos, query),
      languages: DemoData.languages.map((e) => e.toEntity()).toList(),
      primaryTrend: _trendFor(query.window, 38000, 4200),
      secondaryTrend: _trendFor(query.window, 35200, 3100),
      tertiaryTrend: _trendFor(query.window, 32000, 2800),
    );
  }

  List<RepoEntity> _filterRepos(List<RepoEntity> repos, TrendingQuery query) {
    final language = query.language.trim().toLowerCase();
    if (!query.hasLanguageFilter) return repos;
    return repos
        .where((repo) => repo.language.trim().toLowerCase() == language)
        .toList(growable: false);
  }

  List<double> _trendFor(TrendingWindow window, int base, int variance) {
    final scale = switch (window) {
      TrendingWindow.today => 1.0,
      TrendingWindow.week => 1.18,
      TrendingWindow.month => 1.36,
    };
    return DemoData.generateStarTrend(
      (base * scale).round(),
      (variance * scale).round(),
    );
  }
}
