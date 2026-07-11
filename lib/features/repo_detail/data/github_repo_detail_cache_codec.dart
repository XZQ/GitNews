import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_activity_event.dart';
import '../../../core/github/github_api_support.dart';
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
    'activities': digest.activities.map(_activityToJson).toList(),
  };
}

RepoDetailDigest repoDetailDigestFromJson(Map<String, Object?> json) {
  return RepoDetailDigest(
    repo: githubRepoEntityFromJson(json['repo']),
    contributors: GitHubJson.list(
      json['contributors'],
    ).map(_contributorFromJson).toList(),
    relatedRepos: GitHubJson.list(
      json['relatedRepos'],
    ).map(githubRepoEntityFromJson).toList(),
    primaryTrend: GitHubJson.doubleList(json['primaryTrend']),
    compareTrend: GitHubJson.doubleList(json['compareTrend']),
    activities: json['activities'] == null ? const [] : GitHubJson.list(json['activities']).map(_activityFromJson).toList(growable: false),
  );
}

Map<String, Object?> _contributorToJson(ContributorEntity contributor) {
  return {
    'login': contributor.login,
    'contributions': contributor.contributions,
    'avatarAccentArgb': contributor.avatarAccentArgb,
  };
}

ContributorEntity _contributorFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return ContributorEntity(
    login: GitHubJson.string(json['login']),
    contributions: GitHubJson.intValue(json['contributions']),
    avatarAccentArgb: GitHubJson.intValue(json['avatarAccentArgb']),
  );
}

Map<String, Object?> _activityToJson(RepoActivityEvent activity) {
  return {
    'repoFullName': activity.repoFullName,
    'type': activity.type.name,
    'title': activity.title,
    'actorLogin': activity.actorLogin,
    'occurredAt': activity.occurredAt.toUtc().toIso8601String(),
    'htmlUrl': activity.htmlUrl,
    'basis': activity.basis.name,
  };
}

RepoActivityEvent _activityFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return RepoActivityEvent(
    repoFullName: GitHubJson.string(json['repoFullName']),
    type: RepoActivityType.values.firstWhere(
      (value) => value.name == GitHubJson.string(json['type']),
      orElse: () => RepoActivityType.other,
    ),
    title: GitHubJson.string(json['title']),
    actorLogin: GitHubJson.string(json['actorLogin']),
    occurredAt: DateTime.parse(
      GitHubJson.string(json['occurredAt']),
    ).toUtc(),
    htmlUrl: GitHubJson.nullableString(json['htmlUrl']),
    basis: MetricBasis.fromName(GitHubJson.nullableString(json['basis'])),
  );
}
