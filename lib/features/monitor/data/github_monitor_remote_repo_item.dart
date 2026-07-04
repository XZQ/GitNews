import '../../../core/domain/repo_entity.dart';

class GithubMonitorRemoteRepoItem {
  const GithubMonitorRemoteRepoItem({
    required this.repo,
    required this.openIssues,
    required this.pushedAt,
  });

  final RepoEntity repo;
  final int openIssues;
  final DateTime? pushedAt;

  GithubMonitorRemoteRepoItem copyWith({RepoEntity? repo}) {
    return GithubMonitorRemoteRepoItem(
      repo: repo ?? this.repo,
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }
}
