import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';

void main() {
  group('CacheMetaDao', () {
    late LocalDatabase db;
    late CacheMetaDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = CacheMetaDao(db.executor);
    });

    tearDown(() async => db.close());

    test('lastFetched should return null when key absent', () async {
      expect(await dao.lastFetched('missing'), isNull);
    });

    test('upsert then lastFetched should return the stored time', () async {
      final t = DateTime.utc(2026, 6, 30, 10);
      await dao.upsert('k', t);
      expect(await dao.lastFetched('k'), t);
    });

    test('upsert should replace existing time for the same key', () async {
      await dao.upsert('k', DateTime.utc(2026, 6, 30, 10));
      await dao.upsert('k', DateTime.utc(2026, 6, 30, 11));
      expect(await dao.lastFetched('k'), DateTime.utc(2026, 6, 30, 11));
    });

    test('delete should remove the key', () async {
      await dao.upsert('k', DateTime.utc(2026, 6, 30, 10));
      await dao.delete('k');
      expect(await dao.lastFetched('k'), isNull);
    });

    test('keys should be independent', () async {
      await dao.upsert('a', DateTime.utc(2026, 6, 30, 10));
      await dao.upsert('b', DateTime.utc(2026, 6, 30, 11));
      expect(await dao.lastFetched('a'), DateTime.utc(2026, 6, 30, 10));
      expect(await dao.lastFetched('b'), DateTime.utc(2026, 6, 30, 11));
    });

    test('prune retains recent validation metadata', () async {
      final now = DateTime.utc(2026, 10, 12);
      await dao.upsert('expired', now.subtract(const Duration(days: 3)));
      await dao.upsert('recent', now.subtract(const Duration(hours: 1)));

      expect(await dao.pruneStale(now: now, retainFor: const Duration(days: 2)), ['expired']);
      expect(await dao.lastFetched('expired'), isNull);
      expect(await dao.lastFetched('recent'), now.subtract(const Duration(hours: 1)));
    });

    test('prune tolerates asynchronous database deletion failures', () async {
      await db.close();

      expect(await dao.pruneStale(now: DateTime.utc(2026, 10, 12), retainFor: const Duration(days: 2)), isEmpty);
    });

    test('prune keeps etag-only placeholder rows', () async {
      final now = DateTime.utc(2026, 10, 12);
      // 仅写 ETag 的行 last_fetched_at=0:没有成功拉取语义,
      // 清掉会丢失条件请求校验器,必须保留。
      await dao.writeEtag('etag-only', 'W/"abc"');
      await dao.markValidationFailed('failed-marker');
      await dao.upsert('expired', now.subtract(const Duration(days: 3)));

      expect(await dao.pruneStale(now: now, retainFor: const Duration(days: 2)), ['expired']);
      expect(await dao.readEtag('etag-only'), 'W/"abc"');
      expect(await dao.hasFailedValidation('failed-marker'), isTrue);
    });

    test('prune exempts user-data prefixes', () async {
      final now = DateTime.utc(2026, 10, 12);
      final old = now.subtract(const Duration(days: 3));
      await dao.upsert('repo_snapshot_history:v1:owner/repo', old);
      await dao.upsert('monitor_observation:v1:owner/repo', old);
      await dao.upsert('github_resource:v1:expired', old);

      final pruned = await dao.pruneStale(now: now, retainFor: const Duration(days: 2), excludePrefixes: const ['repo_snapshot_history:', 'monitor_observation:']);

      expect(pruned, ['github_resource:v1:expired']);
      expect(await dao.lastFetched('repo_snapshot_history:v1:owner/repo'), old);
      expect(await dao.lastFetched('monitor_observation:v1:owner/repo'), old);
    });

    test('upsert clears a previous validation failure marker', () async {
      await dao.markValidationFailed('k');
      expect(await dao.hasFailedValidation('k'), isTrue);
      await dao.upsert('k', DateTime.utc(2026, 10, 12));
      expect(await dao.hasFailedValidation('k'), isFalse);
    });
  });

  group('CacheMetaDao ETag', () {
    late LocalDatabase db;
    late CacheMetaDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = CacheMetaDao(db.executor);
    });

    tearDown(() async => db.close());

    test('readEtag should return null when key absent', () async {
      expect(await dao.readEtag('missing'), isNull);
    });

    test('writeEtag then readEtag should round-trip', () async {
      await dao.upsert('k', DateTime.utc(2026, 7, 6));
      await dao.writeEtag('k', 'W/"abc"');
      expect(await dao.readEtag('k'), 'W/"abc"');
    });

    test('writeEtag should preserve last_fetched_at', () async {
      final t = DateTime.utc(2026, 7, 6, 10);
      await dao.upsert('k', t);
      await dao.writeEtag('k', 'W/"abc"');
      expect(await dao.lastFetched('k'), t);
    });

    test('writeEtag on missing key inserts row with zero timestamp', () async {
      await dao.writeEtag('k', 'W/"def"');
      expect(await dao.readEtag('k'), 'W/"def"');
      expect(await dao.lastFetched('k'), DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });

    test('delete should clear etag too', () async {
      await dao.upsert('k', DateTime.utc(2026, 7, 6));
      await dao.writeEtag('k', 'W/"abc"');
      await dao.delete('k');
      expect(await dao.readEtag('k'), isNull);
      expect(await dao.lastFetched('k'), isNull);
    });

    test('validators should round-trip ETag and Last-Modified together', () async {
      await dao.upsert('k', DateTime.utc(2026, 7, 19));
      await dao.writeValidators('k', const HttpCacheValidators(etag: 'W/"feed-1"', lastModified: 'Sat, 18 Jul 2026 04:47:25 GMT'));

      final validators = await dao.readValidators('k');

      expect(validators.etag, 'W/"feed-1"');
      expect(validators.lastModified, 'Sat, 18 Jul 2026 04:47:25 GMT');
    });
  });
}
