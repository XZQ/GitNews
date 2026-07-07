import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/local_project_repository.dart';
import '../domain/project_repository.dart';

export '../domain/project_repository.dart' show ProjectDigest;

final projectDigestProvider = FutureProvider<ProjectDigest>((ref) async {
  try {
    return await ref.watch(projectRepositoryProvider).getDigest();
  } on AppException {
    rethrow;
  } catch (error, stack) {
    throw error.asAppException(stack);
  }
});

/* 深度报告顶部搜索关键词。空字符串表示不过滤当前报告数据。 */
final projectSearchQueryProvider = StateProvider<String>((ref) => '');

/* 应用本地搜索后的深度报告摘要。 */
final filteredProjectDigestProvider =
    FutureProvider<ProjectDigest>((ref) async {
  final query = ref.watch(projectSearchQueryProvider);
  final digest = await ref.watch(projectDigestProvider.future);
  return filterProjectDigest(digest, query);
});

ProjectDigest filterProjectDigest(ProjectDigest digest, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return digest;

  return ProjectDigest(
    repos: filterProjectRepos(digest.repos, keyword),
    contributors: filterProjectContributors(digest.contributors, keyword),
    primaryTrend: digest.primaryTrend,
    secondaryTrend: digest.secondaryTrend,
  );
}

List<RepoEntity> filterProjectRepos(List<RepoEntity> repos, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return repos;

  return [
    for (final repo in repos)
      if (_repoSearchText(repo).contains(keyword)) repo,
  ];
}

List<ContributorEntity> filterProjectContributors(
  List<ContributorEntity> contributors,
  String query,
) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return contributors;

  return [
    for (final contributor in contributors)
      if (_contributorSearchText(contributor).contains(keyword)) contributor,
  ];
}

String _repoSearchText(RepoEntity repo) {
  return [
    repo.fullName,
    repo.description,
    repo.language,
  ].join(' ').toLowerCase();
}

String _contributorSearchText(ContributorEntity contributor) {
  return [
    contributor.login,
    contributor.contributions.toString(),
  ].join(' ').toLowerCase();
}
