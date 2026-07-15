import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/domain/repository_feed.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/project/data/github_project_repository.dart';
import 'package:github_news/features/project/data/project_cache_keys.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeRepositoryFeed implements RepositoryFeed {
  const _FakeRepositoryFeed(this.repos);

  final List<RepoEntity> repos;

  @override
  Future<DataResult<RepositoryFeedDigest>> load() async {
    return DataResult(freshness: DataFreshness.live, data: RepositoryFeedDigest(repos: repos, primaryTrend: const [], secondaryTrend: const []));
  }
}

void main() {
  late LocalDatabase database;
  late JsonSnapshotCacheDao cache;
  late _MockDio dio;
  final now = DateTime.utc(
    2026,
    7,
    11,
    12,
  );

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(database.executor, CacheMetaDao(database.executor));
    dio = _MockDio();
  });

  tearDown(() => database.close());

  test('does not reuse contributors cached for another repository set', () async {
    await cache.upsert(
      key: 'project:github:contributors:v1',
      payload: {
        'contributors': [
          {'login': 'cached-for-a', 'contributions': 99, 'avatarAccentArgb': 0xFF000001}
        ]
      },
      now: now,
    );
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      return Response<Object?>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: path.endsWith('/events')
            ? <Object?>[]
            : <Object?>[
                {'login': 'fresh-for-b', 'contributions': 7}
              ],
      );
    });
    final repository = GithubProjectRepository(
      repositoryFeed: const _FakeRepositoryFeed([_repoB]),
      dio: dio,
      cache: cache,
      now: () => now,
    );

    final result = await repository.getDigest();

    expect(result.data.contributors.single.login, 'fresh-for-b');
    expect(await cache.read(projectContributorsCacheKey(repos: const ['b/two'], cacheScope: 'anonymous')), isNotNull);
    verify(() => dio.get<Object?>('/repos/b/two/contributors', queryParameters: const {'per_page': 8}, options: any(named: 'options'))).called(1);
  });

  test('merges repository events by time and caps the activity feed', () async {
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      final data = path.endsWith('/contributors')
          ? <Object?>[]
          : path.endsWith('/events')
              ? List<Object?>.generate(20, (index) => _activityPayload(repo: path.contains('/a/one/') ? 'a/one' : 'b/two', hour: path.contains('/a/one/') ? index : index + 20))
              : throw StateError('Unexpected request: $path');
      return Response<Object?>(requestOptions: RequestOptions(path: path), statusCode: 200, data: data);
    });
    final repository = GithubProjectRepository(
      repositoryFeed: const _FakeRepositoryFeed([_repoA, _repoB]),
      dio: dio,
      cache: cache,
      now: () => now,
    );

    final result = await repository.getDigest();

    expect(result.data.activities, hasLength(30));
    expect(result.data.activities.first.occurredAt.isAfter(result.data.activities.last.occurredAt), isTrue);
    expect(result.data.activities.map((event) => event.repoFullName).toSet(), containsAll({'a/one', 'b/two'}));
  });

  test('uses stale aggregated activities while GitHub is rate limited', () async {
    final key = projectActivitiesCacheKey(repos: const ['b/two'], cacheScope: 'anonymous');
    await cache.upsert(
      key: key,
      payload: {
        'activities': [
          {'repoFullName': 'b/two', 'type': 'release', 'title': 'published: cached release', 'actorLogin': 'octocat', 'occurredAt': '2026-07-10T10:00:00.000Z', 'htmlUrl': null, 'basis': 'observed'}
        ]
      },
      now: now.subtract(const Duration(hours: 2)),
    );
    final repository = GithubProjectRepository(
      repositoryFeed: const _FakeRepositoryFeed([_repoB]),
      dio: dio,
      cache: cache,
      now: () => now,
      isRateLimited: () => true,
    );

    final result = await repository.getDigest();

    expect(result.data.activities.single.title, 'published: cached release');
    verifyNever(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')));
  });
}

Map<String, Object?> _activityPayload({required String repo, required int hour}) {
  return {
    'type': 'PushEvent',
    'actor': {'login': 'octocat'},
    'repo': {'name': repo},
    'created_at': DateTime.utc(2026, 7, 9).add(Duration(hours: hour)).toIso8601String(),
    'payload': {
      'commits': [
        {'sha': 'sha-$hour', 'message': 'event-$hour'}
      ]
    }
  };
}

const _repoA = RepoEntity(
  fullName: 'a/one',
  description: 'Repository A',
  language: 'Dart',
  starCount: 10,
  starDelta: 1,
  forkCount: 2,
  accentArgb: 0xFF00A389,
);

const _repoB = RepoEntity(
  fullName: 'b/two',
  description: 'Repository B',
  language: 'Dart',
  starCount: 20,
  starDelta: 2,
  forkCount: 3,
  accentArgb: 0xFF00A389,
);
