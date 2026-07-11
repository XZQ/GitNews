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
    return DataResult(
      freshness: DataFreshness.live,
      data: RepositoryFeedDigest(
        repos: repos,
        primaryTrend: const [],
        secondaryTrend: const [],
      ),
    );
  }
}

void main() {
  late LocalDatabase database;
  late JsonSnapshotCacheDao cache;
  late _MockDio dio;
  final now = DateTime.utc(2026, 7, 11, 12);

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(
      database.executor,
      CacheMetaDao(database.executor),
    );
    dio = _MockDio();
  });

  tearDown(() => database.close());

  test('does not reuse contributors cached for another repository set', () async {
    await cache.upsert(
      key: 'project:github:contributors:v1',
      payload: {
        'contributors': [
          {
            'login': 'cached-for-a',
            'contributions': 99,
            'avatarAccentArgb': 0xFF000001,
          },
        ],
      },
      now: now,
    );
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Object?>(
        requestOptions: RequestOptions(path: '/contributors'),
        statusCode: 200,
        data: [
          {
            'login': 'fresh-for-b',
            'contributions': 7,
          },
        ],
      ),
    );
    final repository = GithubProjectRepository(
      repositoryFeed: const _FakeRepositoryFeed([_repoB]),
      dio: dio,
      cache: cache,
      now: () => now,
    );

    final result = await repository.getDigest();

    expect(result.data.contributors.single.login, 'fresh-for-b');
    expect(
      await cache.read(
        projectContributorsCacheKey(
          repos: const ['b/two'],
          cacheScope: 'anonymous',
        ),
      ),
      isNotNull,
    );
    verify(
      () => dio.get<Object?>(
        '/repos/b/two/contributors',
        queryParameters: const {'per_page': 8},
        options: any(named: 'options'),
      ),
    ).called(1);
  });
}

const _repoB = RepoEntity(
  fullName: 'b/two',
  description: 'Repository B',
  language: 'Dart',
  starCount: 20,
  starDelta: 2,
  forkCount: 3,
  accentArgb: 0xFF00A389,
);
