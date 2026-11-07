import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/monitor/data/monitor_observation_dao.dart';
import 'package:github_news/features/monitor/domain/monitor_observation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  test('a storage read failure does not overwrite existing history', () async {
    await dao.record(observation(day: 1, stars: 100));
    expect(await dao.read('owner/repo'), hasLength(1));

    final failing = _ReadFailingCache(database.executor, CacheMetaDao(database.executor));
    final failingDao = MonitorObservationDao(failing);
    expect((await failingDao.readWithStatus('owner/repo')).corrupted, isTrue);
    await failingDao.record(observation(day: 2, stars: 200));

    // 读取失败时既不写回,也不清除原有历史。
    expect(failing.upsertCalls, 0);
    expect(await dao.read('owner/repo'), hasLength(1));
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

/* 模拟存储层的临时故障(非 payload 损坏),用于验证不会用空历史覆盖写回。 */
class _ReadFailingCache extends JsonSnapshotCacheDao {
  _ReadFailingCache(DatabaseExecutor db, CacheMetaDao meta) : super(db, meta);

  int upsertCalls = 0;

  @override
  Future<Map<String, Object?>?> read(String key) async {
    throw const AppException(kind: AppExceptionKind.cache, cause: 'simulated storage failure', meta: {'op': 'jsonSnapshot.read'});
  }

  @override
  Future<void> upsert({required String key, required Map<String, Object?> payload, required DateTime now, bool validated = true}) async {
    upsertCalls++;
  }
}
