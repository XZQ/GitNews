import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';
import 'database_schema.dart';

// 数据库文件名。
const String kDatabaseFileName = 'github_news.db';

// 1 GB 容量上限。
const int kMaxDatabaseBytes = 1 << 30; // 1024 * 1024 * 1024

// 容量超限时,删除最旧条目的比例。
const double _kEvictRatio = 0.1;

/* 
*本地 SQLite 数据库封装。
*设计目标:
*- 抽象掉 driver(sqflite_common_ffi),业务层只看到 [executor]
*- schema 升级链集中在 database_schema.dart 维护
*- 提供 [sizeInBytes] / [clearAll] / [enforceCap] 三个全局能力
*通用 schema 包含一张 [cache_meta] 表,任何按 cache_key 走 TTL 的模块
*都通过 [CacheMetaDao] 共享它,避免每个 feature 各自维护 meta。
*/
class LocalDatabase {
  LocalDatabase._(this._db, this.path);

  final Database _db;
  final String path;

  // 当前 schema 版本。每次新增迁移在 database_schema.dart 的迁移链末尾追加并自增此值。
  static const int _kCurrentVersion = 3;

  /* 
  *业务方拿到这个 executor 后,在自己的 DAO 内执行 SQL。
  *故意返回 [DatabaseExecutor] 而不是 [Database],让 feature DAO
  *无法调用 `close()` / `setVersion` 等基础设施级 API。
  */
  DatabaseExecutor get executor => _db;

  /* 
  *启动入口:初始化 FFI、打开或创建数据库、跑迁移。
  *桌面端通过 `sqflite_common_ffi` 提供的 `databaseFactoryFfi` 走原生
  *SQLite;移动端未来接入时同样能复用此实现(sqflite_common_ffi 在
  *Android/iOS 同样可工作)。
  */
  static Future<LocalDatabase> open() async {
    sqfliteFfiInit();
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, kDatabaseFileName);
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _kCurrentVersion,
        onCreate: bootstrapSchema,
        onUpgrade: onUpgradeSchema,
      ),
    );
    final instance = LocalDatabase._(db, dbPath);
    // 启动容量清扫:兜底覆盖「只浏览 trending/monitor 不进 ai_news」时
    // 快照表从不触发 1GB 上限清理的场景(ai_news 落盘后另有触发)。
    unawaited(instance.enforceCap());
    return instance;
  }

  /* 
  *仅用于测试:用 `:memory:` 打开,文件不落地。
  *每次 call 返回独立的内存库;`path` 字段对 `:memory:` 库无意义。
  */
  static Future<LocalDatabase> openInMemory() async {
    sqfliteFfiInit();
    const name = ':memory:';
    final db = await databaseFactoryFfi.openDatabase(
      name,
      options: OpenDatabaseOptions(
        version: _kCurrentVersion,
        onCreate: bootstrapSchema,
        onUpgrade: onUpgradeSchema,
      ),
    );
    return LocalDatabase._(db, name);
  }

  /*
  *当前 DB 文件大小(字节)。失败时返回 0。
  */
  int sizeInBytes() {
    try {
      final f = File(path);
      if (!f.existsSync()) return 0;
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  // 所有业务表名清单。新增表只需在此列表追加一行,`clearAll` 自动覆盖。
  static const List<String> _kBusinessTables = [
    'ai_news_item',
    'trending_snapshot_cache',
    'json_snapshot_cache',
    'cache_meta',
  ];

  /* 
  *清空所有业务表 + VACUUM。
  *通用清理入口:遍历 [_kBusinessTables] 逐表 DELETE,新增表只需在
  *列表中追加即可,无需修改此方法。不直接 DROP 是为了保留 schema,
  *清理后立刻可以重新写入。
  */
  Future<void> clearAll() async {
    try {
      for (final table in _kBusinessTables) {
        await _db.delete(table);
      }
      await _db.execute('VACUUM');
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'clearAll'},
      );
    }
  }

  /* 
  *容量守卫:超过 [kMaxDatabaseBytes] 时按 cached_at ASC 删旧 10%。
  *设计为「尽力而为」:在 [upsert] 完成后异步触发,失败只吞掉——
  *容量清理失败不应阻塞业务请求,下一轮再尝试。
  */
  Future<void> enforceCap() async {
    try {
      final size = sizeInBytes();
      if (size <= kMaxDatabaseBytes) return;
      final aiRows =
          await _db.rawQuery('SELECT COUNT(*) AS c FROM ai_news_item');
      final trendingRows = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM trending_snapshot_cache',
      );
      final jsonRows =
          await _db.rawQuery('SELECT COUNT(*) AS c FROM json_snapshot_cache');
      final aiCount = aiRows.isEmpty ? 0 : (aiRows.first['c'] as int? ?? 0);
      final trendingCount =
          trendingRows.isEmpty ? 0 : (trendingRows.first['c'] as int? ?? 0);
      final jsonCount =
          jsonRows.isEmpty ? 0 : (jsonRows.first['c'] as int? ?? 0);
      final count = aiCount + trendingCount + jsonCount;
      if (count == 0) {
        await _db.execute('VACUUM');
        return;
      }
      final evict = (count * _kEvictRatio).floor().clamp(1, count);
      if (aiCount > 0) {
        await _db.rawDelete(
          '''
          DELETE FROM ai_news_item
          WHERE id IN (
            SELECT id FROM ai_news_item
            ORDER BY cached_at ASC
            LIMIT ?
          )
          ''',
          [evict.clamp(1, aiCount)],
        );
      }
      if (trendingCount > 0) {
        await _db.rawDelete(
          '''
          DELETE FROM trending_snapshot_cache
          WHERE cache_key IN (
            SELECT cache_key FROM trending_snapshot_cache
            ORDER BY cached_at ASC
            LIMIT ?
          )
          ''',
          [evict.clamp(1, trendingCount)],
        );
      }
      if (jsonCount > 0) {
        await _db.rawDelete(
          '''
          DELETE FROM json_snapshot_cache
          WHERE cache_key IN (
            SELECT cache_key FROM json_snapshot_cache
            ORDER BY cached_at ASC
            LIMIT ?
          )
          ''',
          [evict.clamp(1, jsonCount)],
        );
      }
      await _db.execute('VACUUM');
    } catch (_) {
      // 容量超限清理失败不阻塞业务,下次再试
    }
  }

  /* 
  *关闭底层连接。生产环境由 OS 回收,主要用于测试 tearDown。
  */
  Future<void> close() => _db.close();
}
