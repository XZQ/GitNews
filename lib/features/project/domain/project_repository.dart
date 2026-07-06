import '../../../core/domain/contributor_entity.dart';
import '../../../core/domain/repo_entity.dart';

export '../../../core/domain/contributor_entity.dart' show ContributorEntity;
export '../../../core/domain/repo_entity.dart' show RepoEntity;

/// 项目深度报告页(探索 / 发现 / 活动)共用的摘要。
class ProjectDigest {
  const ProjectDigest({
    required this.repos,
    required this.contributors,
    required this.primaryTrend,
    required this.secondaryTrend,
  });

  final List<RepoEntity> repos;
  final List<ContributorEntity> contributors;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;

  bool get isEmpty => repos.isEmpty && contributors.isEmpty;
}

/// 项目深度报告仓库。
///
/// 当前实现组合 trending 摘要与本地贡献者 fixture,
/// 后续可替换为 GitHub API(repo + contributors + activity)。
abstract interface class ProjectRepository {
  Future<ProjectDigest> getDigest();
}
