import '../../../core/demo_data.dart';

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

  final List<DemoRepo> trendingRepos;
  final List<DemoRepo> recentRepos;
  final List<DemoLanguage> languages;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;
  final List<double> tertiaryTrend;

  List<DemoRepo> get allRepos => [...trendingRepos, ...recentRepos];

  bool get isEmpty => trendingRepos.isEmpty && recentRepos.isEmpty;
}

/// 趋势数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为 GitHub API + 本地快照缓存。
abstract interface class TrendingRepository {
  Future<TrendingDigest> getDigest();
}
