import '../../../core/domain/repo_entity.dart';
import 'entities.dart';

/// 仓库详情页需要的一组本地情报数据。
class RepoDetailDigest {
  const RepoDetailDigest({
    required this.repo,
    required this.contributors,
    required this.relatedRepos,
    required this.primaryTrend,
    required this.compareTrend,
  });

  final RepoEntity repo;
  final List<ContributorEntity> contributors;
  final List<RepoEntity> relatedRepos;
  final List<double> primaryTrend;
  final List<double> compareTrend;
}

/// 仓库详情数据仓库。
///
/// 当前实现默认读取 GitHub Repository / Contributors / Search API 并使用
/// 本地快照缓存;远端失败时可回退过期缓存或本地详情种子数据。
abstract interface class RepoDetailRepository {
  Future<RepoDetailDigest> getDetail(String fullName);
}
