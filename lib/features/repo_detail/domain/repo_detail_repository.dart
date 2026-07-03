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
/// 当前实现读取本地模拟数据,后续可替换为 GitHub REST/GraphQL + 本地缓存。
abstract interface class RepoDetailRepository {
  Future<RepoDetailDigest> getDetail(String fullName);
}
