import '../../../core/github/github_api_support.dart';
import '../../../core/github/github_repo_activity_codec.dart';
import '../../../core/github/github_repo_entity_codec.dart';
import '../domain/entities.dart';
import '../domain/repo_detail_repository.dart';

Map<String, Object?> repoDetailDigestToJson(RepoDetailDigest digest) {
  return {
    'repo': githubRepoEntityToJson(digest.repo),
    'contributors': digest.contributors.map(_contributorToJson).toList(),
    'relatedRepos': digest.relatedRepos.map(githubRepoEntityToJson).toList(),
    'primaryTrend': digest.primaryTrend,
    'compareTrend': digest.compareTrend,
    'activities': repoActivitiesToJson(digest.activities)
  };
}

RepoDetailDigest repoDetailDigestFromJson(Map<String, Object?> json) {
  return RepoDetailDigest(
    repo: githubRepoEntityFromJson(json['repo']),
    contributors: GitHubJson.list(json['contributors']).map(_contributorFromJson).toList(),
    relatedRepos: GitHubJson.list(json['relatedRepos']).map(githubRepoEntityFromJson).toList(),
    primaryTrend: GitHubJson.doubleList(json['primaryTrend']),
    compareTrend: GitHubJson.doubleList(json['compareTrend']),
    activities: json['activities'] == null ? const [] : repoActivitiesFromJson(json['activities']),
  );
}

Map<String, Object?> _contributorToJson(ContributorEntity contributor) {
  return {'login': contributor.login, 'contributions': contributor.contributions, 'avatarAccentArgb': contributor.avatarAccentArgb};
}

ContributorEntity _contributorFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return ContributorEntity(
    login: GitHubJson.string(json['login']),
    contributions: GitHubJson.intValue(json['contributions']),
    avatarAccentArgb: GitHubJson.intValue(json['avatarAccentArgb']),
  );
}
