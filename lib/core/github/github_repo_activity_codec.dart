import '../domain/data_freshness.dart';
import '../domain/repo_activity_event.dart';
import 'github_api_support.dart';

List<Object?> repoActivitiesToJson(Iterable<RepoActivityEvent> activities) {
  return activities.map(repoActivityToJson).toList(growable: false);
}

List<RepoActivityEvent> repoActivitiesFromJson(Object? raw) {
  return GitHubJson.list(raw).map(repoActivityFromJson).toList(growable: false);
}

Map<String, Object?> repoActivityToJson(RepoActivityEvent activity) {
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

RepoActivityEvent repoActivityFromJson(Object? raw) {
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
