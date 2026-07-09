import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';

/* 
*LocalDatabase 商业级稳定性测试:
*- schema 完整性:启动后所有业务表必须存在(防止迁移漏建表导致运行时崩溃);
*- clearAll 保留 schema 但清空数据;
*- enforceCap 为兼容旧调用保留 no-op(项目不再自动限制容量)。
*
*注:真正的「旧版本 DB 文件 → 当前版本」迁移往返需要注入历史 schema,
*当前迁移链(v1→v2、v2→v3)均为幂等的 `CREATE TABLE IF NOT EXISTS`,
*无 ALTER / 数据变换,数据丢失风险极低;此处锁定 schema 完整性与容量守卫行为。
*/
void main() {
  group('LocalDatabase schema', () {
    test('openInMemory creates all business tables at current version', () async {
      final db = await LocalDatabase.openInMemory();
      addTearDown(db.close);
      final rows = await db.executor.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = rows.map((r) => r['name'] as String).toSet();
      const expected = [
        'cache_meta',
        'ai_news_item',
        'trending_snapshot_cache',
        'json_snapshot_cache',
      ];
      for (final table in expected) {
        expect(
          names,
          contains(table),
          reason: '$table 必须存在,否则对应 DAO 会运行时报错',
        );
      }
    });

    test('clearAll empties business tables but keeps schema', () async {
      final db = await LocalDatabase.openInMemory();
      addTearDown(db.close);
      await db.executor.insert(
        'cache_meta',
        {'cache_key': 'k1', 'last_fetched_at': 1},
      );
      await db.clearAll();
      final rows = await db.executor.query('cache_meta');
      expect(rows, isEmpty);
      final meta = await db.executor.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='cache_meta'",
      );
      expect(meta, isNotEmpty, reason: 'schema 应保留,清理后可立即重写');
    });

    test('enforceCap keeps data because automatic capacity limit is disabled', () async {
      final db = await LocalDatabase.openInMemory();
      addTearDown(db.close);
      await db.executor.insert(
        'cache_meta',
        {'cache_key': 'k1', 'last_fetched_at': 1},
      );
      await db.enforceCap();
      final rows = await db.executor.query('cache_meta');
      expect(rows.length, 1, reason: '项目不再设置自动容量上限');
    });

    test('business tables list covers all created tables', () async {
      // clearAll 依赖 _kBusinessTables 覆盖所有业务表;若漏列会残留数据。
      final db = await LocalDatabase.openInMemory();
      addTearDown(db.close);
      await db.executor.insert(
        'cache_meta',
        {'cache_key': 'k1', 'last_fetched_at': 1},
      );
      await db.executor.insert(
        'ai_news_item',
        {
          'id': 'a',
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
          'cached_at': 0,
        },
      );
      await db.clearAll();
      expect(await db.executor.query('cache_meta'), isEmpty);
      expect(await db.executor.query('ai_news_item'), isEmpty);
    });
  });
}
