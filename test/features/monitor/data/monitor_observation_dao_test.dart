import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/monitor/data/monitor_observation_dao.dart';
import 'package:github_news/features/monitor/domain/monitor_observation.dart';

void main() {
  late LocalDatabase database;
  late JsonSnapshotCacheDao cache;
  late MonitorObservationDao dao;

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(database.executor, CacheMetaDao(database.executor));
    dao = MonitorObservationDao(cache);
  });

  tearDown(() => database.close());

  test('same-day record overwrites the existing observation', () async {
    await dao.record(observation(day: 1, hour: 1, stars: 100));
    await dao.record(observation(day: 1, hour: 20, stars: 150));

    final points = await dao.read('owner/repo');

    expect(points, hasLength(1));
    expect(points.single.stars, 150);
    expect(points.single.observedAt.hour, 20);
  });

  test('latestBefore returns the previous distinct local day', () async {
    await dao.record(observation(day: 1, stars: 100));
    await dao.record(observation(day: 2, stars: 200));
    final current = observation(day: 3, stars: 300);

    final previous = await dao.latestBefore(repoFullName: current.repoFullName, observedAt: current.observedAt);

    expect(previous?.stars, 200);
  });

  test('malformed payload is removed and treated as empty history', () async {
    await cache.upsert(key: 'monitor_observation:v1:owner/repo', payload: {'points': 'not-a-list'}, now: DateTime(2026, 7, 1));

    expect(await dao.read('owner/repo'), isEmpty);
    expect(await cache.read('monitor_observation:v1:owner/repo'), isNull);
  });

  test('history keeps only the latest 90 local days', () async {
    final start = DateTime(2026, 1, 1);
    for (var i = 0; i < 95; i++) {
      final at = start.add(Duration(days: i));
      await dao.record(MonitorObservation(repoFullName: 'owner/repo', stars: i, forks: i, openIssues: i, observedAt: at));
    }

    final points = await dao.read('owner/repo');

    expect(points, hasLength(90));
    expect(points.first.stars, 5);
    expect(points.last.stars, 94);
  });
}

MonitorObservation observation({int day = 1, int hour = 12, int stars = 100}) {
  return MonitorObservation(repoFullName: 'owner/repo', stars: stars, forks: 10, openIssues: 2, observedAt: DateTime(2026, 7, day, hour));
}
