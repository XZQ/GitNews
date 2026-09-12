import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_check_status.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/monitor/data/github_monitor_cache_codec.dart';
import 'package:github_news/features/monitor/data/github_monitor_repository.dart';
import 'package:github_news/features/monitor/data/monitor_alert_event_dao.dart';
import 'package:github_news/features/monitor/data/monitor_observation_dao.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_observation.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:github_news/features/monitor/domain/monitor_rule.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late LocalDatabase database;
  late JsonSnapshotCacheDao cache;
  late MonitorObservationDao observations;
  late MonitorAlertEventDao alerts;
  late _MockDio dio;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(database.executor, CacheMetaDao(database.executor));
    observations = MonitorObservationDao(cache);
    alerts = MonitorAlertEventDao(database.executor);
    dio = _MockDio();
  });

  tearDown(() => database.close());

  GithubMonitorRepository buildRepository({required DateTime now, List<String> repos = const ['owner/repo'], bool rateLimited = false}) {
    return GithubMonitorRepository(
      dio: dio,
      cache: cache,
      observationDao: observations,
      alertDao: alerts,
      enabledRuleIds: MonitorRuleIds.all,
      now: () => now,
      repos: repos,
      cacheKey: 'monitor:test',
      isRateLimited: () => rateLimited,
    );
  }

  test('fresh cache never records observations or creates alerts', () async {
    final now = DateTime(2026, 7, 2, 12);
    await cache.upsert(key: 'monitor:test', payload: monitorDigestToJson(emptyDigest()), now: now);
    final repository = buildRepository(now: now);

    final result = await repository.getDigest();

    expect(result.freshness, DataFreshness.freshCache);
    expect(await observations.read('owner/repo'), isEmpty);
    expect(await alerts.list(includeArchived: true), isEmpty);
    verifyNever(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')));
  });

  test('remote success records observation and persists rule alerts', () async {
    final now = DateTime(2026, 7, 2, 12);
    await observations.record(MonitorObservation(repoFullName: 'owner/repo', stars: 2000, forks: 10, openIssues: 1, observedAt: DateTime(2026, 7, 1, 12)));
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => okResponse(stars: 2200, forks: 60, issues: 9));
    final repository = buildRepository(now: now);

    final result = await repository.getDigest(force: true);

    expect(result.freshness, DataFreshness.live);
    expect(await observations.read('owner/repo'), hasLength(2));
    expect(await alerts.list(includeArchived: true), hasLength(4));
    expect(result.data.alerts, hasLength(4));
  });

  test('remote failure returns stale cache without creating alerts', () async {
    final cachedAt = DateTime(2026, 7, 1, 10);
    final now = DateTime(2026, 7, 2, 12);
    await cache.upsert(key: 'monitor:test', payload: monitorDigestToJson(emptyDigest()), now: cachedAt);
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenThrow(
      DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ApiEndpointsConfig.githubRepoPath('owner/repo')),
      ),
    );
    final repository = buildRepository(now: now);

    final result = await repository.getDigest();

    expect(result.freshness, DataFreshness.staleCache);
    expect(await alerts.list(includeArchived: true), isEmpty);
    expect(await observations.read('owner/repo'), isEmpty);
  });

  test('failed force refresh retains the durable snapshot across repository recreation', () async {
    final now = DateTime.utc(2026, 9, 12, 12);
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => okResponse(stars: 1234, forks: 12, issues: 1));
    await buildRepository(now: now).getDigest();
    final before = await cache.read('monitor:test');
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenThrow(StateError('simulated offline'));
    final later = now.add(const Duration(minutes: 1));
    final result = await buildRepository(now: later).getDigest(force: true);
    expect(result.freshness, DataFreshness.staleCache);
    expect(result.data.monitoredRepos.single.starCount, 1234);
    expect((await cache.read('monitor:test'))!['repos'], before!['repos']);
    expect(result.validatedAt, now);
    expect(await cache.isFresh(key: 'monitor:test', ttl: monitorRemoteCacheTtl, now: later), isFalse);
    final reopened = await buildRepository(now: later).getDigest();
    expect(reopened.freshness, DataFreshness.staleCache);
    expect(reopened.data.monitoredRepos.single.fullName, 'owner/repo');
    expect(reopened.data.monitoredRepos.single.starCount, 1234);
    expect(await observations.read('owner/repo'), hasLength(1));
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => okResponse(stars: 1250, forks: 12, issues: 1));
    final recovered = await buildRepository(now: later).getDigest(force: true);
    expect(recovered.freshness, DataFreshness.live);
    expect(monitorDigestFromJson((await cache.read('monitor:test'))!).monitoredRepos.single.starCount, 1250);
    expect(await cache.isFresh(key: 'monitor:test', ttl: monitorRemoteCacheTtl, now: later), isTrue);
  });

  test('first offline load keeps the requested repositories without demo metrics', () async {
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenThrow(StateError('simulated offline'));
    final result = await buildRepository(now: DateTime.utc(2026, 9, 12), repos: ['user/first', 'user/second']).getDigest(force: true);
    expect(result.data.monitoredRepos.map((repo) => repo.fullName), ['user/first', 'user/second']);
    expect(result.data.stats.monitoredCount, 2);
    expect(result.data.monitoredRepos.every((repo) => repo.valueBasis == MetricBasis.unavailable), isTrue);
    expect(monitorDigestFromJson((await cache.read('monitor:test'))!).checks.values.every((check) => check.validatedAt == null), isTrue);
    expect(await alerts.list(includeArchived: true), isEmpty);
  });

  test('empty monitor selection does not request remote or show demo repositories', () async {
    final result = await buildRepository(now: DateTime.utc(2026, 9, 12), repos: []).getDigest(force: true);
    expect(result.data.monitoredRepos, isEmpty);
    expect(result.data.stats.monitoredCount, 0);
    verifyNever(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')));
  });

  test('partial failure preserves every repository and its last real observation after recreation', () async {
    final firstAt = DateTime.utc(2026, 9, 10, 12);
    const repos = ['owner/first', 'owner/second'];
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((call) async {
      final name = (call.positionalArguments.single as String).substring('/repos/'.length);
      return okResponse(stars: 100, forks: 10, issues: 1, fullName: name);
    });
    await buildRepository(now: firstAt, repos: repos).getDigest();
    final nextAt = firstAt.add(const Duration(days: 1));
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((call) async {
      final path = call.positionalArguments.single as String;
      if (path.endsWith('/second')) {
        throw DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: path),
        );
      }
      return okResponse(stars: 110, forks: 10, issues: 1, fullName: 'owner/first');
    });
    final result = await buildRepository(now: nextAt, repos: repos).getDigest(force: true);
    expect(result.freshness, DataFreshness.staleCache);
    expect(result.validatedAt, firstAt);
    expect(result.data.monitoredRepos.map((repo) => repo.fullName), repos);
    expect(result.data.monitoredRepos.map((repo) => repo.starCount), [110, 100]);
    expect(result.data.stats.monitoredCount, 2);
    expect(result.data.checks['owner/second']?.failure, RepoCheckFailure.network);
    expect(result.data.checks['owner/second']?.validatedAt, firstAt);
    expect(result.data.checks['owner/second']?.attemptedAt, nextAt);
    expect(result.data.checks['owner/first']?.validatedAt, nextAt);
    expect(await observations.read('owner/first'), hasLength(2));
    expect(await observations.read('owner/second'), hasLength(1));
    expect(await cache.isFresh(key: 'monitor:test', ttl: monitorRemoteCacheTtl, now: nextAt), isFalse);
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenThrow(StateError('offline'));
    final reopened = await buildRepository(now: nextAt, repos: repos).getDigest();
    expect(reopened.data.monitoredRepos.map((repo) => repo.starCount), [110, 100]);
    expect(reopened.data.checks['owner/second']?.validatedAt, firstAt);
    expect(reopened.data.checks['owner/first']?.validatedAt, nextAt);
    expect(reopened.validatedAt, firstAt);
  });

  test('first partial response persists pending repositories without invented metrics or timestamps', () async {
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((call) async {
      final path = call.positionalArguments.single as String;
      if (path.endsWith('/second')) {
        throw StateError('offline');
      }
      return okResponse(stars: 100, forks: 10, issues: 1, fullName: 'owner/first');
    });
    final result = await buildRepository(now: DateTime.utc(2026, 9, 12), repos: ['owner/first', 'owner/second']).getDigest();
    expect(result.freshness, DataFreshness.staleCache);
    expect(result.validatedAt, isNull);
    expect(result.data.monitoredRepos.last.valueBasis, MetricBasis.unavailable);
    expect(result.data.checks['owner/second']?.validatedAt, isNull);
    expect(result.data.stats.monitoredCount, 2);
    expect(await observations.read('owner/second'), isEmpty);
  });

  test('rate limit gate preserves checked timestamps and makes no network requests', () async {
    final result = await buildRepository(now: DateTime.utc(2026, 9, 12), rateLimited: true).getDigest(force: true);
    expect(result.data.checks['owner/repo']?.failure, RepoCheckFailure.rateLimit);
    expect(result.data.checks['owner/repo']?.validatedAt, isNull);
    verifyNever(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')));
  });

  for (final (code, failure) in [(401, RepoCheckFailure.unauthorized), (404, RepoCheckFailure.notFound), (429, RepoCheckFailure.rateLimit)]) {
    test('persists controlled failure reason for HTTP $code', () async {
      final options = RequestOptions(path: ApiEndpointsConfig.githubRepoPath('owner/repo'));
      when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: code),
        ),
      );
      final result = await buildRepository(now: DateTime.utc(2026, 9, 12)).getDigest(force: true);
      expect(result.data.checks['owner/repo']?.failure, failure);
      expect(monitorDigestFromJson((await cache.read('monitor:test'))!).checks['owner/repo']?.failure, failure);
    });
  }

  test('repository redirect retains the monitored subscription identity', () async {
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => okResponse(stars: 9999, forks: 1, issues: 1, fullName: 'other/repo'));
    final result = await buildRepository(now: DateTime.utc(2026, 9, 12)).getDigest(force: true);
    expect(result.data.monitoredRepos.single.fullName, 'owner/repo');
    expect(result.data.monitoredRepos.single.starCount, 9999);
    expect(result.data.checks['owner/repo']?.failure, isNull);
    expect(await observations.read('owner/repo'), hasLength(1));
    expect(await observations.read('other/repo'), isEmpty);
  });
}

MonitorDigest emptyDigest() {
  return const MonitorDigest(
    monitoredRepos: [],
    alerts: [],
    stats: MonitorStats(monitoredCount: 0, monitoredDelta: 0, unreadAlertCount: 0, unreadAlertDelta: 0, triggeredTodayCount: 0, triggeredTodayDelta: 0, totalAlertCount: 0, totalAlertDelta: 0),
  );
}

Response<Map<String, Object?>> okResponse({required int stars, required int forks, required int issues, String fullName = 'owner/repo'}) {
  return Response<Map<String, Object?>>(
    requestOptions: RequestOptions(path: ApiEndpointsConfig.githubRepoPath(fullName)),
    statusCode: 200,
    data: {'full_name': fullName, 'description': 'Repository', 'language': 'Dart', 'stargazers_count': stars, 'forks_count': forks, 'open_issues_count': issues, 'pushed_at': '2026-07-02T08:00:00Z'},
  );
}
