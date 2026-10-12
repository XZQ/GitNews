import 'dart:async';

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

/*
*替换 HTTP 出口，保留真实资源缓存与报告聚合。
*/
class _MockDio extends Mock implements Dio {}

/*
*固定报告仓库集合，让部分失败和缓存比较使用同一查询。
*/
class _RepositoryFeed implements RepositoryFeed {
  const _RepositoryFeed();

  @override
  /* 返回两个仓库的成功信息流，不掩盖子资源的失败状态。 */
  Future<DataResult<RepositoryFeedDigest>> load() async => const DataResult(
    data: RepositoryFeedDigest(repos: [_repoA, _repoB], primaryTrend: [], secondaryTrend: []),
    freshness: DataFreshness.live,
  );
}

/*
*让活动缓存先失败、贡献者检查后失败，验证两个异步分支都被监听。
*/
class _FailingFreshnessCache extends JsonSnapshotCacheDao {
  _FailingFreshnessCache(LocalDatabase db, {required this.contributorKey, required this.activityKey}) : super(db.executor, CacheMetaDao(db.executor));

  // 两类聚合缓存的稳定查询标识。
  final String contributorKey;
  final String activityKey;

  // 延后贡献者失败，制造活动分支先拒绝的时序。
  final Completer<bool> contributorCheck = Completer<bool>();

  // 保证测试只在两个检查均被监听后注入失败。
  final Completer<void> contributorStarted = Completer<void>();
  final Completer<void> activityStarted = Completer<void>();

  // 活动缓存检查的受控故障。
  final StateError activityFailure = StateError('simulated activity cache failure');

  @override
  /* 保持真实读取，仅替换两种 TTL 检查的异步失败时序。 */
  Future<bool> isFresh({required String key, required Duration ttl, required DateTime now}) {
    if (key == contributorKey) {
      contributorStarted.complete();
      return contributorCheck.future;
    }
    if (key == activityKey) {
      activityStarted.complete();
      return Future<bool>.error(activityFailure);
    }
    return super.isFresh(key: key, ttl: ttl, now: now);
  }
}

/* 检查部分失败不会覆盖完整快照，以及成功空结果可复用。 */
void main() {
  late LocalDatabase db;
  late JsonSnapshotCacheDao cache;
  late CacheMetaDao meta;
  late _MockDio dio;
  late DateTime now;
  late Set<String> failedPaths;
  late List<String> requests;
  late int contributions;
  late bool empty;
  final contributorKey = projectContributorsCacheKey(repos: const ['a/one', 'b/two'], cacheScope: 'anonymous');
  final activityKey = projectActivitiesCacheKey(repos: const ['a/one', 'b/two'], cacheScope: 'anonymous');

  setUpAll(() => registerFallbackValue(Options()));
  setUp(() async {
    db = await LocalDatabase.openInMemory();
    meta = CacheMetaDao(db.executor);
    cache = JsonSnapshotCacheDao(db.executor, meta);
    dio = _MockDio();
    now = DateTime.utc(2026, 10, 12, 12);
    failedPaths = {};
    requests = [];
    contributions = 7;
    empty = false;
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      requests.add(path);
      final request = RequestOptions(path: path);
      if (failedPaths.contains(path)) {
        throw DioException(requestOptions: request, type: DioExceptionType.connectionError, error: 'simulated offline');
      }
      final isA = path.contains('/a/one/');
      return Response<Object?>(
        requestOptions: request,
        statusCode: 200,
        data: empty
            ? <Object?>[]
            : path.endsWith('/contributors')
            ? <Object?>[
                {'login': isA ? 'alice' : 'bob', 'contributions': contributions},
              ]
            : <Object?>[_activity(isA ? 'a/one' : 'b/two', now)],
      );
    });
  });
  tearDown(() => db.close());

  /* 创建独立仓库实例，验证持久化状态而非对象内存结果。 */
  GithubProjectRepository repository() => GithubProjectRepository(repositoryFeed: const _RepositoryFeed(), dio: dio, cache: cache, now: () => now);

  test('failed contributor refresh preserves the complete snapshot and retries after recovery', () async {
    final originalTime = now;
    final first = await repository().getDigest();
    expect(first.data.contributors.map((item) => item.login), containsAll(['alice', 'bob']));
    final snapshot = await cache.read(contributorKey);
    now = now.add(const Duration(minutes: 31));
    contributions = 99;
    failedPaths.add('/repos/b/two/contributors');

    final failed = await repository().getDigest();
    expect(failed.freshness, DataFreshness.staleCache);
    expect(failed.data.contributors.map((item) => item.contributions), [7, 7]);
    expect(await cache.read(contributorKey), snapshot);
    expect(await meta.lastFetched(contributorKey), originalTime);
    expect(await meta.hasFailedValidation(contributorKey), isTrue);

    failedPaths.clear();
    final restored = await repository().getDigest();
    expect(restored.data.contributors.map((item) => item.contributions), [99, 99]);
    expect(await meta.lastFetched(contributorKey), now);
    expect(await meta.hasFailedValidation(contributorKey), isFalse);
    expect(requests.where((path) => path == '/repos/b/two/contributors'), hasLength(3));
  });

  test('failed activity refresh preserves complete activities and degrades report freshness', () async {
    final originalTime = now;
    await repository().getDigest();
    final snapshot = await cache.read(activityKey);
    now = now.add(const Duration(minutes: 31));
    failedPaths.add('/repos/b/two/events');

    final failed = await repository().getDigest();
    expect(failed.freshness, DataFreshness.staleCache);
    expect(failed.data.activities.map((event) => event.repoFullName), containsAll(['a/one', 'b/two']));
    expect(failed.data.activities.every((event) => event.occurredAt == originalTime), isTrue);
    expect(await cache.read(activityKey), snapshot);
    expect(await meta.lastFetched(activityKey), originalTime);
    expect(await meta.hasFailedValidation(activityKey), isTrue);

    failedPaths.clear();
    final restored = await repository().getDigest();
    expect(restored.data.activities.every((event) => event.occurredAt == now), isTrue);
    expect(await meta.lastFetched(activityKey), now);
    expect(await meta.hasFailedValidation(activityKey), isFalse);
    expect(requests.where((path) => path == '/repos/b/two/events'), hasLength(3));
  });

  test('a successful empty contributor and activity response is cached and remains empty on failure', () async {
    empty = true;
    final first = await repository().getDigest();
    expect(first.data.contributors, isEmpty);
    expect(first.data.activities, isEmpty);
    expect(first.freshness, DataFreshness.live);
    expect(await cache.read(contributorKey), {'contributors': <Object?>[]});
    expect(await cache.read(activityKey), {'activities': <Object?>[]});

    requests.clear();
    final cached = await repository().getDigest();
    expect(cached.freshness, DataFreshness.freshCache);
    expect(cached.data.contributors, isEmpty);
    expect(requests, isEmpty);

    now = now.add(const Duration(minutes: 31));
    failedPaths.addAll(['/repos/a/one/contributors', '/repos/b/two/contributors', '/repos/a/one/events', '/repos/b/two/events']);
    final failed = await repository().getDigest();
    expect(failed.freshness, DataFreshness.staleCache);
    expect(failed.data.contributors, isEmpty);
    expect(failed.data.activities, isEmpty);
  });

  test('first partial failure does not commit an incomplete aggregate as a successful snapshot', () async {
    failedPaths.addAll(['/repos/b/two/contributors', '/repos/b/two/events']);
    final failed = await repository().getDigest();
    expect(failed.freshness, DataFreshness.seed);
    expect(failed.data.activities, isEmpty);
    expect(await cache.read(contributorKey), isNull);
    expect(await cache.read(activityKey), isNull);
    expect((await meta.lastFetched(contributorKey))?.millisecondsSinceEpoch ?? 0, 0);
    expect((await meta.lastFetched(activityKey))?.millisecondsSinceEpoch ?? 0, 0);
    expect(await meta.hasFailedValidation(contributorKey), isTrue);
    expect(await meta.hasFailedValidation(activityKey), isTrue);
  });

  test('concurrent cache failures are both observed before the report fails', () async {
    await repository().getDigest();
    final failingCache = _FailingFreshnessCache(db, contributorKey: contributorKey, activityKey: activityKey);
    final failingRepository = GithubProjectRepository(repositoryFeed: const _RepositoryFeed(), dio: dio, cache: failingCache, now: () => now);
    final report = failingRepository.getDigest();
    final assertion = expectLater(report, throwsA(same(failingCache.activityFailure)));
    await Future.wait<void>([failingCache.contributorStarted.future, failingCache.activityStarted.future]);
    await Future<void>.delayed(Duration.zero);
    failingCache.contributorCheck.completeError(StateError('simulated contributor cache failure'));
    await assertion;
  });
}

/* 最小 PushEvent 保留仓库和时间，供完整活动快照比较。 */
Map<String, Object?> _activity(String repo, DateTime occurredAt) => {
  'type': 'PushEvent',
  'actor': {'login': 'octocat'},
  'repo': {'name': repo},
  'created_at': occurredAt.toIso8601String(),
  'payload': {'commits': <Object?>[]},
};

const _repoA = RepoEntity(fullName: 'a/one', description: 'A', language: 'Dart', starCount: 10, starDelta: 0, forkCount: 1, accentArgb: 0xff000001);
const _repoB = RepoEntity(fullName: 'b/two', description: 'B', language: 'Dart', starCount: 20, starDelta: 0, forkCount: 2, accentArgb: 0xff000002);
