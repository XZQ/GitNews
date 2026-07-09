import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';

void main() {
  group('JsonSnapshotCacheDao', () {
    late LocalDatabase db;
    late JsonSnapshotCacheDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = JsonSnapshotCacheDao(
        db.executor,
        CacheMetaDao(db.executor),
      );
    });

    tearDown(() async => db.close());

    test('read should return null when key absent', () async {
      expect(await dao.read('missing'), isNull);
    });

    test('upsert then read should return stored payload', () async {
      await dao.upsert(
        key: 'digest',
        payload: const {
          'items': ['openai/codex'],
          'count': 1,
        },
        now: DateTime.utc(2026, 7, 4, 10),
      );

      expect(await dao.read('digest'), {
        'items': ['openai/codex'],
        'count': 1,
      });
    });

    test('isFresh should respect ttl', () async {
      await dao.upsert(
        key: 'digest',
        payload: const {'ok': true},
        now: DateTime.utc(2026, 7, 4, 10),
      );

      expect(
        await dao.isFresh(
          key: 'digest',
          ttl: const Duration(minutes: 5),
          now: DateTime.utc(2026, 7, 4, 10, 4, 59),
        ),
        isTrue,
      );
      expect(
        await dao.isFresh(
          key: 'digest',
          ttl: const Duration(minutes: 5),
          now: DateTime.utc(2026, 7, 4, 10, 5),
        ),
        isFalse,
      );
    });

    test('delete should remove payload and freshness marker', () async {
      await dao.upsert(
        key: 'digest',
        payload: const {'ok': true},
        now: DateTime.utc(2026, 7, 4, 10),
      );

      await dao.delete('digest');

      expect(await dao.read('digest'), isNull);
      expect(
        await dao.isFresh(
          key: 'digest',
          ttl: const Duration(minutes: 5),
          now: DateTime.utc(2026, 7, 4, 10, 1),
        ),
        isFalse,
      );
    });
  });

  group('JsonSnapshotCacheDao ETag', () {
    late LocalDatabase db;
    late JsonSnapshotCacheDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = JsonSnapshotCacheDao(
        db.executor,
        CacheMetaDao(db.executor),
      );
    });

    tearDown(() async => db.close());

    test('readWithEtag returns null payload and etag when key absent', () async {
      final entry = await dao.readWithEtag('missing');
      expect(entry.payload, isNull);
      expect(entry.etag, isNull);
    });

    test('upsertWithEtag stores payload and etag together', () async {
      await dao.upsertWithEtag(
        key: 'k1',
        payload: const {'a': 1},
        etag: 'W/"abc"',
        now: DateTime.utc(2026, 7, 6),
      );
      final entry = await dao.readWithEtag('k1');
      expect(entry.payload, {'a': 1});
      expect(entry.etag, 'W/"abc"');
    });

    test('upsert (without etag) preserves existing etag', () async {
      await dao.upsertWithEtag(
        key: 'k1',
        payload: const {'a': 1},
        etag: 'W/"abc"',
        now: DateTime.utc(2026, 7, 6),
      );
      await dao.upsert(
        key: 'k1',
        payload: const {'a': 2},
        now: DateTime.utc(2026, 7, 6, 1),
      );
      final entry = await dao.readWithEtag('k1');
      expect(entry.payload, {'a': 2});
      expect(entry.etag, 'W/"abc"');
    });

    test('upsertWithEtag with null etag preserves existing etag', () async {
      await dao.upsertWithEtag(
        key: 'k1',
        payload: const {'a': 1},
        etag: 'W/"abc"',
        now: DateTime.utc(2026, 7, 6),
      );
      await dao.upsertWithEtag(
        key: 'k1',
        payload: const {'a': 2},
        etag: null,
        now: DateTime.utc(2026, 7, 6, 1),
      );
      final entry = await dao.readWithEtag('k1');
      expect(entry.payload, {'a': 2});
      expect(entry.etag, 'W/"abc"');
    });
  });
}
