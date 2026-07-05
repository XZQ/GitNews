import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_provenance.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/tech_hotspot/data/tech_hotspot_history_dao.dart';

void main() {
  late LocalDatabase db;
  late TechHotspotHistoryDao dao;

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    dao = TechHotspotHistoryDao(
      JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('trend should require at least two observed days', () async {
    await dao.record(
      id: 'github-agent',
      heat: 60,
      mentions: 120,
      relatedRepos: 1000,
      capturedAt: DateTime.utc(2026, 7, 1, 8),
    );

    expect(await dao.trend('github-agent'), isNull);
  });

  test('trend should calculate observed heat values and growth', () async {
    await dao.record(
      id: 'github-agent',
      heat: 60,
      mentions: 120,
      relatedRepos: 1000,
      capturedAt: DateTime.utc(2026, 7, 1, 8),
    );
    await dao.record(
      id: 'github-agent',
      heat: 72,
      mentions: 160,
      relatedRepos: 1250,
      capturedAt: DateTime.utc(2026, 7, 2, 8),
    );

    final trend = await dao.trend('github-agent');

    expect(trend?.heatValues, [60, 72]);
    expect(trend?.growth, 25);
    expect(trend?.provenance, DataProvenance.observed);
  });

  test('record should overwrite same-day snapshot and cap history', () async {
    for (var i = 0; i < techHotspotHistoryMaxPoints + 2; i++) {
      await dao.record(
        id: 'github-agent',
        heat: 40 + i,
        mentions: 100 + i,
        relatedRepos: 1000 + i,
        capturedAt: DateTime.utc(2026, 7, 1).add(Duration(days: i)),
      );
    }
    await dao.record(
      id: 'github-agent',
      heat: 99,
      mentions: 999,
      relatedRepos: 1999,
      capturedAt: DateTime.utc(2026, 8, 1, 23),
    );

    final trend = await dao.trend('github-agent');

    expect(trend?.heatValues.length, techHotspotHistoryMaxPoints);
    expect(trend?.heatValues.last, 99);
  });
}
