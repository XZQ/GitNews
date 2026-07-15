import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_activity_event.dart';
import 'package:github_news/core/github/github_repo_activity_source.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/repo_detail/data/github_repo_detail_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test('parses supported GitHub activity event types from real payload fields', () {
    final events = [
      _event(type: 'PushEvent', payload: {
        'commits': [
          {'sha': 'abc123', 'message': 'feat: trusted activity'}
        ]
      }),
      _event(type: 'IssuesEvent', payload: {
        'action': 'opened',
        'issue': {'title': 'Crash on startup', 'html_url': 'https://github.com/owner/repo/issues/1'}
      }),
      _event(type: 'PullRequestEvent', payload: {
        'action': 'closed',
        'pull_request': {'title': 'Fix cache scope', 'html_url': 'https://github.com/owner/repo/pull/2'}
      }),
      _event(type: 'ReleaseEvent', payload: {
        'action': 'published',
        'release': {'name': 'Version 1.3.0', 'tag_name': 'v1.3.0', 'html_url': 'https://github.com/owner/repo/releases/v1.3.0'}
      }),
      _event(type: 'WatchEvent', payload: const {})
    ].map((json) => parseGitHubRepoActivity(json, fallbackRepoFullName: 'fallback/repo'));

    expect(events.map((event) => event.type), [RepoActivityType.push, RepoActivityType.issues, RepoActivityType.pullRequest, RepoActivityType.release, RepoActivityType.other]);
    expect(events.first.title, 'feat: trusted activity');
    expect(events.first.actorLogin, 'octocat');
    expect(events.first.repoFullName, 'owner/repo');
    expect(events.first.basis, MetricBasis.observed);
    expect(events.elementAt(1).title, 'opened: Crash on startup');
    expect(events.elementAt(2).title, 'closed: Fix cache scope');
    expect(events.elementAt(3).title, 'published: Version 1.3.0');
    expect(events.last.title, 'WatchEvent');
  });

  test('github detail repository loads activities from repository events', () async {
    final database = await LocalDatabase.openInMemory();
    addTearDown(database.close);
    final cache = JsonSnapshotCacheDao(database.executor, CacheMetaDao(database.executor));
    final dio = _MockDio();
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      final data = switch (path) {
        '/repos/owner/repo' => _repoPayload,
        '/repos/owner/repo/contributors' => <Object?>[],
        '/repos/owner/repo/events' => <Object?>[
            _event(type: 'PushEvent', payload: {
              'commits': [
                {'sha': 'abc123', 'message': 'feat: trusted activity'}
              ]
            })
          ],
        _ => throw StateError('Unexpected object request: $path')
      };
      return Response<Object?>(requestOptions: RequestOptions(path: path), statusCode: 200, data: data);
    });
    when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer(
      (invocation) async => Response<Map<String, Object?>>(requestOptions: RequestOptions(path: invocation.positionalArguments.first as String), statusCode: 200, data: const {'items': <Object?>[]}),
    );
    final repository = GithubRepoDetailRepository(
        dio: dio,
        cache: cache,
        now: () => DateTime.utc(
              2026,
              7,
              11,
              12,
            ));

    final result = await repository.getDetail('owner/repo');

    expect(result.freshness, DataFreshness.live);
    expect(result.data.activities.single.title, 'feat: trusted activity');
    verify(() => dio.get<Object?>('/repos/owner/repo/events', queryParameters: const {'per_page': 20}, options: any(named: 'options'))).called(1);
  });
}

const _repoPayload = <String, Object?>{
  'full_name': 'owner/repo',
  'description': 'Repository',
  'language': 'Dart',
  'stargazers_count': 10,
  'forks_count': 2,
  'open_issues_count': 1,
  'pushed_at': '2026-07-11T09:00:00Z'
};

Map<String, Object?> _event({required String type, required Map<String, Object?> payload}) {
  return {
    'type': type,
    'actor': {'login': 'octocat'},
    'repo': {'name': 'owner/repo'},
    'created_at': '2026-07-11T10:00:00Z',
    'payload': payload
  };
}
