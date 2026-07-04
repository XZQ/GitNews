import 'entities.dart';

/// GitHub 热榜查询时间窗。
enum TrendingWindow {
  today,
  week,
  month;

  static TrendingWindow fromValue(String value) {
    return switch (value) {
      'week' => TrendingWindow.week,
      'month' => TrendingWindow.month,
      _ => TrendingWindow.today,
    };
  }
}

/// GitHub 热榜查询条件。
class TrendingQuery {
  const TrendingQuery({
    this.window = TrendingWindow.today,
    this.language = 'all',
  });

  final TrendingWindow window;
  final String language;

  bool get hasLanguageFilter => language.trim().toLowerCase() != 'all';
}

/// 趋势页需要的一组本地情报数据。
class TrendingDigest {
  const TrendingDigest({
    required this.trendingRepos,
    required this.recentRepos,
    required this.languages,
    required this.primaryTrend,
    required this.secondaryTrend,
    required this.tertiaryTrend,
  });

  final List<RepoEntity> trendingRepos;
  final List<RepoEntity> recentRepos;
  final List<LanguageEntity> languages;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;
  final List<double> tertiaryTrend;

  List<RepoEntity> get allRepos => [...trendingRepos, ...recentRepos];

  bool get isEmpty => trendingRepos.isEmpty && recentRepos.isEmpty;
}

/// 趋势数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为 GitHub API + 本地快照缓存。
abstract interface class TrendingRepository {
  Future<TrendingDigest> getDigest({
    TrendingQuery query = const TrendingQuery(),
  });
}
