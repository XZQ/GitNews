import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/*
*真正的「旧版本 DB → 当前版本」迁移往返测试。
*
*策略:在内存库里手动构造 v1 schema(只有 cache_meta + ai_news_item),
*插入真实数据,然后调用 `onUpgradeSchema(db, 1, 5)` 跑完整迁移链,
*验证:
*- 所有 v5 表已创建;
*- v1 已存在的数据未丢;
*- ai_news_state 等「用户状态」表在新库中可用。
*
*另外覆盖 v2→v5、v3→v5、v4→v5 三条部分链路,确保任一旧版本都能升到当前。
*/
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  Future<Database> openRawV1Db() async {
    final db = await databaseFactoryFfi.openDatabase(':memory:', options: OpenDatabaseOptions(version: 1));
    // v1 原始 schema:cache_meta + ai_news_item + 索引。
    await db.execute(
      '''
      CREATE TABLE cache_meta (
        cache_key        TEXT PRIMARY KEY,
        last_fetched_at  INTEGER NOT NULL,
        payload_hash     TEXT,
        ext1             TEXT,
        ext2             INTEGER,
        ext3             REAL
      )
    ''',
    );
    await db.execute(
      '''
      CREATE TABLE ai_news_item (
        id            TEXT PRIMARY KEY,
        category      TEXT NOT NULL,
        title         TEXT NOT NULL,
        title_en      TEXT NOT NULL,
        summary       TEXT NOT NULL,
        source        TEXT NOT NULL,
        url           TEXT NOT NULL,
        permalink     TEXT NOT NULL,
        published_at  INTEGER NOT NULL,
        score         INTEGER NOT NULL,
        selected      INTEGER NOT NULL,
        cached_at     INTEGER NOT NULL
      )
    ''',
    );
    return db;
  }

  Future<void> seedV1Data(DatabaseExecutor db) async {
    await db.insert('cache_meta', {'cache_key': 'legacy-key', 'last_fetched_at': 100});
    await db.insert('ai_news_item', {
      'id': 'legacy-news',
      'category': 'aiModels',
      'title': 'legacy',
      'title_en': 'legacy',
      'summary': 's',
      'source': 'src',
      'url': 'u',
      'permalink': 'p',
      'published_at': 0,
      'score': 1,
      'selected': 0,
      'cached_at': 0
    });
  }

  Future<Set<String>> tableNames(DatabaseExecutor db) async {
    final rows = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    return rows.map((r) => r['name'] as String).toSet();
  }

  group('onUpgradeSchema full chain v1→v5', () {
    test('v1 → v5 creates all current-version tables', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await seedV1Data(db);

      await onUpgradeSchema(db, 1, 5);

      final names = await tableNames(db);
      const expected = ['cache_meta', 'ai_news_item', 'trending_snapshot_cache', 'json_snapshot_cache', 'monitor_alert_event', 'ai_news_state'];
      for (final table in expected) {
        expect(names, contains(table), reason: '$table 必须在 v1→v5 升级后存在');
      }
    });

    test('v1 → v5 preserves legacy data', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await seedV1Data(db);

      await onUpgradeSchema(db, 1, 5);

      final cacheRows = await db.query('cache_meta');
      expect(cacheRows, hasLength(1));
      expect(cacheRows.first['cache_key'], 'legacy-key');

      final newsRows = await db.query('ai_news_item');
      expect(newsRows, hasLength(1));
      expect(newsRows.first['id'], 'legacy-news');
    });

    test('v1 → v5 makes ai_news_state writable for user read-later state', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await onUpgradeSchema(db, 1, 5);

      await db.insert('ai_news_state', {
        'item_id': 'state-1',
        'read_at': 1,
        'read_later_at': 2,
        'category': 'aiModels',
        'title': 't',
        'title_en': 'te',
        'summary': 's',
        'source': 'src',
        'url': 'u',
        'permalink': 'p',
        'published_at': 0,
        'score': 1,
        'selected': 0,
        'updated_at': 0
      });
      final rows = await db.query('ai_news_state');
      expect(rows, hasLength(1), reason: '升级后 ai_news_state 必须可读写');
    });
  });

  group('onUpgradeSchema partial chains', () {
    test('v2 → v5 adds json_snapshot_cache + monitor_alert_event + ai_news_state', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      // 先把 v1→v2 跑掉,模拟一个停留在 v2 的库。
      await onUpgradeSchema(db, 1, 2);
      final tablesAfterV2 = await tableNames(db);
      expect(tablesAfterV2, contains('trending_snapshot_cache'));
      expect(tablesAfterV2, isNot(contains('ai_news_state')));

      await onUpgradeSchema(db, 2, 5);
      final tablesAfterV5 = await tableNames(db);
      expect(tablesAfterV5, containsAll(['json_snapshot_cache', 'monitor_alert_event', 'ai_news_state']));
    });

    test('v3 → v5 adds monitor_alert_event + ai_news_state', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await onUpgradeSchema(db, 1, 3);

      await onUpgradeSchema(db, 3, 5);
      final tables = await tableNames(db);
      expect(tables, containsAll(['monitor_alert_event', 'ai_news_state']));
    });

    test('v4 → v5 adds ai_news_state only', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await onUpgradeSchema(db, 1, 4);
      final before = await tableNames(db);
      expect(before, isNot(contains('ai_news_state')));

      await onUpgradeSchema(db, 4, 5);
      final after = await tableNames(db);
      expect(after, contains('ai_news_state'));
    });
  });

  group('onUpgradeSchema idempotence', () {
    test('running the same migration chain twice does not error', () async {
      final db = await openRawV1Db();
      addTearDown(db.close);
      await onUpgradeSchema(db, 1, 5);
      // 再跑一次 onUpgrade(1,5) 也不应报错:所有 DDL 均为 IF NOT EXISTS。
      await onUpgradeSchema(db, 1, 5);
      final tables = await tableNames(db);
      expect(tables, contains('ai_news_state'));
    });
  });
}
