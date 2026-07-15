import '../config/api_endpoints_config.dart';
import '../domain/data_freshness.dart';
import '../domain/repo_activity_event.dart';
import '../errors/app_exception.dart';
import 'github_api_support.dart';
import 'github_resource_cache.dart';

Future<DataResult<List<RepoActivityEvent>>> fetchGitHubRepoActivities({required GitHubResourceCache resources, required String fullName, int perPage = 20}) async {
  try {
    final result = await resources.getList(url: ApiEndpointsConfig.githubRepoEventsPath(fullName), queryParameters: {'per_page': perPage});
    return result.map((data) => data.map((raw) => parseGitHubRepoActivity(raw, fallbackRepoFullName: fullName)).toList(growable: false));
  } on FormatException catch (error, stack) {
    throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
  } on TypeError catch (error, stack) {
    throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
  }
}

RepoActivityEvent parseGitHubRepoActivity(Object? raw, {required String fallbackRepoFullName}) {
  final json = GitHubJson.map(raw);
  final rawType = GitHubJson.string(json['type']);
  final payload = _mapOrEmpty(json['payload']);
  final repo = _mapOrEmpty(json['repo']);
  final actor = _mapOrEmpty(json['actor']);
  final repoFullName = _nullableString(repo['name']) ?? fallbackRepoFullName;
  final parsed = _parsePayload(rawType, payload, repoFullName);
  return RepoActivityEvent(
    repoFullName: repoFullName,
    type: parsed.type,
    title: parsed.title,
    actorLogin: _nullableString(actor['login']) ?? '',
    occurredAt: DateTime.parse(GitHubJson.string(json['created_at'])).toUtc(),
    htmlUrl: parsed.htmlUrl,
    basis: MetricBasis.observed,
  );
}

_ParsedActivity _parsePayload(String rawType, Map<String, Object?> payload, String repoFullName) {
  return switch (rawType) {
    'PushEvent' => _parsePush(payload, repoFullName),
    'IssuesEvent' => _parseIssue(payload),
    'PullRequestEvent' => _parsePullRequest(payload),
    'ReleaseEvent' => _parseRelease(payload),
    'CreateEvent' => _parseCreate(payload),
    _ => _ParsedActivity(type: RepoActivityType.other, title: rawType, htmlUrl: '${ApiEndpointsConfig.githubWebBaseUrl}/$repoFullName')
  };
}

_ParsedActivity _parsePush(Map<String, Object?> payload, String repoFullName) {
  final commits = payload['commits'];
  final firstCommit = commits is List && commits.isNotEmpty ? _mapOrEmpty(commits.first) : const <String, Object?>{};
  final sha = _nullableString(firstCommit['sha']);
  return _ParsedActivity(
    type: RepoActivityType.push,
    title: _nullableString(firstCommit['message']) ?? 'PushEvent',
    htmlUrl: sha == null ? '${ApiEndpointsConfig.githubWebBaseUrl}/$repoFullName' : '${ApiEndpointsConfig.githubWebBaseUrl}/$repoFullName/commit/$sha',
  );
}

_ParsedActivity _parseIssue(Map<String, Object?> payload) {
  final issue = _mapOrEmpty(payload['issue']);
  return _ParsedActivity(type: RepoActivityType.issues, title: _actionTitle(payload, issue, fallback: 'IssuesEvent'), htmlUrl: _nullableString(issue['html_url']));
}

_ParsedActivity _parsePullRequest(Map<String, Object?> payload) {
  final pullRequest = _mapOrEmpty(payload['pull_request']);
  return _ParsedActivity(type: RepoActivityType.pullRequest, title: _actionTitle(payload, pullRequest, fallback: 'PullRequestEvent'), htmlUrl: _nullableString(pullRequest['html_url']));
}

_ParsedActivity _parseRelease(Map<String, Object?> payload) {
  final release = _mapOrEmpty(payload['release']);
  final releaseTitle = _nullableString(release['name']) ?? _nullableString(release['tag_name']);
  return _ParsedActivity(type: RepoActivityType.release, title: _withAction(_nullableString(payload['action']), releaseTitle, fallback: 'ReleaseEvent'), htmlUrl: _nullableString(release['html_url']));
}

_ParsedActivity _parseCreate(Map<String, Object?> payload) {
  final refType = _nullableString(payload['ref_type']);
  final ref = _nullableString(payload['ref']);
  final details = [if (refType != null) refType, if (ref != null) ref].join(': ');
  return _ParsedActivity(type: RepoActivityType.create, title: details.isEmpty ? 'CreateEvent' : details, htmlUrl: null);
}

String _actionTitle(Map<String, Object?> payload, Map<String, Object?> subject, {required String fallback}) {
  return _withAction(_nullableString(payload['action']), _nullableString(subject['title']), fallback: fallback);
}

String _withAction(String? action, String? title, {required String fallback}) {
  if (action != null && title != null) {
    return '$action: $title';
  }
  return title ?? action ?? fallback;
}

Map<String, Object?> _mapOrEmpty(Object? value) {
  return value is Map ? value.cast<String, Object?>() : <String, Object?>{};
}

String? _nullableString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value;
}

class _ParsedActivity {
  const _ParsedActivity({required this.type, required this.title, required this.htmlUrl});

  final RepoActivityType type;
  final String title;
  final String? htmlUrl;
}
