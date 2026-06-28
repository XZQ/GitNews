import '../../../core/demo_data.dart';

/// 仓库详情页需要的一组本地情报数据。
class RepoDetailDigest {
  const RepoDetailDigest({
    required this.repo,
    required this.contributors,
    required this.relatedRepos,
    required this.primaryTrend,
    required this.compareTrend,
  });

  final DemoRepo repo;
  final List<DemoContributor> contributors;
  final List<DemoRepo> relatedRepos;
  final List<double> primaryTrend;
  final List<double> compareTrend;
}

/// 仓库详情数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为 GitHub REST/GraphQL + 本地缓存。
abstract interface class RepoDetailRepository {
  Future<RepoDetailDigest> getDetail(String fullName);
}
