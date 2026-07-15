import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
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

  GithubMonitorRepository buildRepository({required DateTime now}) {
    return GithubMonitorRepository(
      dio: dio,
      cache: cache,
      observationDao: observations,
      alertDao: alerts,
      enabledRuleIds: MonitorRuleIds.all,
      now: () => now,
      repos: const ['owner/repo'],
      cacheKey: 'monitor:test',
    );
  }

  test('fresh cache never records observations or creates alerts', () async {
    final now = DateTime(
      2026,
      7,
      2,
      12,
    );
    await cache.upsert(key: 'monitor:test', payload: monitorDigestToJson(emptyDigest()), now: now);
    final repository = buildRepository(now: now);

    final result = await repository.getDigest();

    expect(result.freshness, DataFreshness.freshCache);
    expect(await observations.read('owner/repo'), isEmpty);
    expect(await alerts.list(includeArchived: true), isEmpty);
    verifyNever(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')));
  });

  test('remote success records observation and persists rule alerts', () async {
    final now = DateTime(
      2026,
      7,
      2,
      12,
    );
    await observations.record(MonitorObservation(
      repoFullName: 'owner/repo',
      stars: 2000,
      forks: 10,
      openIssues: 1,
      observedAt: DateTime(2026, 7, 1, 12),
    ));
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => okResponse(stars: 2200, forks: 60, issues: 9));
    final repository = buildRepository(now: now);

    final result = await repository.getDigest(force: true);

    expect(result.freshness, DataFreshness.live);
    expect(await observations.read('owner/repo'), hasLength(2));
    expect(await alerts.list(includeArchived: true), hasLength(4));
    expect(result.data.alerts, hasLength(4));
  });

  test('remote failure returns stale cache without creating alerts', () async {
    final cachedAt = DateTime(
      2026,
      7,
      1,
      10,
    );
    final now = DateTime(
      2026,
      7,
      2,
      12,
    );
    await cache.upsert(key: 'monitor:test', payload: monitorDigestToJson(emptyDigest()), now: cachedAt);
    when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')))
        .thenThrow(DioException(type: DioExceptionType.connectionError, requestOptions: RequestOptions(path: ApiEndpointsConfig.githubRepoPath('owner/repo'))));
    final repository = buildRepository(now: now);

    final result = await repository.getDigest();

    expect(result.freshness, DataFreshness.staleCache);
    expect(await alerts.list(includeArchived: true), isEmpty);
    expect(await observations.read('owner/repo'), isEmpty);
  });
}

MonitorDigest emptyDigest() {
  return const MonitorDigest(
    monitoredRepos: [],
    alerts: [],
    stats: MonitorStats(
      monitoredCount: 0,
      monitoredDelta: 0,
      unreadAlertCount: 0,
      unreadAlertDelta: 0,
      triggeredTodayCount: 0,
      triggeredTodayDelta: 0,
      totalAlertCount: 0,
      totalAlertDelta: 0,
    ),
  );
}

Response<Map<String, Object?>> okResponse({required int stars, required int forks, required int issues}) {
  return Response<Map<String, Object?>>(requestOptions: RequestOptions(path: '/repos/owner/repo'), statusCode: 200, data: {
    'full_name': 'owner/repo',
    'description': 'Repository',
    'language': 'Dart',
    'stargazers_count': stars,
    'forks_count': forks,
    'open_issues_count': issues,
    'pushed_at': '2026-07-02T08:00:00Z'
  });
}
