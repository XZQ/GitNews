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
  });
}
