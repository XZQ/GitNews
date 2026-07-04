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

/// GitHub 热榜榜单类型。
enum TrendingBoard {
  all,
  agent,
  mcp,
  aiCoding,
  newRepos;

  static TrendingBoard fromValue(String value) {
    return switch (value) {
      'agent' => TrendingBoard.agent,
      'mcp' => TrendingBoard.mcp,
      'ai_coding' => TrendingBoard.aiCoding,
      'new_repos' => TrendingBoard.newRepos,
      _ => TrendingBoard.all,
    };
  }

  String get value {
    return switch (this) {
      TrendingBoard.all => 'all',
      TrendingBoard.agent => 'agent',
      TrendingBoard.mcp => 'mcp',
      TrendingBoard.aiCoding => 'ai_coding',
      TrendingBoard.newRepos => 'new_repos',
    };
  }
}

/// GitHub 热榜查询条件。
class TrendingQuery {
  const TrendingQuery({
    this.window = TrendingWindow.today,
    this.language = 'all',
    this.board = TrendingBoard.all,
  });

  final TrendingWindow window;
  final String language;
  final TrendingBoard board;

  bool get hasLanguageFilter => language.trim().toLowerCase() != 'all';
  bool get hasBoardFilter => board != TrendingBoard.all;
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
/// 当前支持本地数据源与 GitHub Search 数据源。GitHub Search 不直接返回
/// Star 增量,远端实现里的增长值是动量代理值;真实历史趋势需要本地快照累积。
abstract interface class TrendingRepository {
  Future<TrendingDigest> getDigest({
    TrendingQuery query = const TrendingQuery(),
  });
}
