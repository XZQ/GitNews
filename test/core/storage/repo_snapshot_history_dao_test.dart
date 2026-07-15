import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/repo_snapshot_history_dao.dart';

void main() {
  late LocalDatabase db;
  late RepoSnapshotHistoryDao dao;

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    final meta = CacheMetaDao(db.executor);
    dao = RepoSnapshotHistoryDao(JsonSnapshotCacheDao(db.executor, meta));
  });

  tearDown(() async {
    await db.close();
  });

  test('starTrend should require at least two observed days', () async {
    await dao.record(fullName: 'openai/codex', stars: 100, forks: 10, capturedAt: DateTime.utc(2026, 7, 1, 8));

    expect(await dao.starTrend('openai/codex'), isNull);
  });

  test('starTrend should return ordered observed values across days', () async {
    await dao.record(fullName: 'openai/codex', stars: 120, forks: 12, capturedAt: DateTime.utc(2026, 7, 2, 8));
    await dao.record(fullName: 'openai/codex', stars: 100, forks: 10, capturedAt: DateTime.utc(2026, 7, 1, 8));

    final trend = await dao.starTrend('openai/codex');

    expect(trend?.values, [100, 120]);
    expect(trend?.basis, MetricBasis.observed);
  });

  test('record should overwrite same-day snapshot and cap history', () async {
    for (var i = 0; i < repoSnapshotHistoryMaxPoints + 2; i++) {
      await dao.record(fullName: 'openai/codex', stars: 100 + i, forks: 10 + i, capturedAt: DateTime.utc(2026, 7, 1).add(Duration(days: i)));
    }
    await dao.record(fullName: 'openai/codex', stars: 999, forks: 99, capturedAt: DateTime.utc(2026, 8, 1, 23));

    final trend = await dao.starTrend('openai/codex');
    final forkTrend = await dao.forkTrend('openai/codex');

    expect(trend?.values.length, repoSnapshotHistoryMaxPoints);
    expect(trend?.values.last, 999);
    expect(forkTrend?.values.last, 99);
  });
}
