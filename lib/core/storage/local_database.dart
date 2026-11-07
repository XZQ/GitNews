import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';
import '../utils/app_logger.dart';
import 'database_schema.dart';

// 数据库文件名。
const String kDatabaseFileName = 'github_news.db';

/* 
*本地 SQLite 数据库封装。
*设计目标:
*- 抽象掉 driver(sqflite_common_ffi),业务层只看到 [executor]
*- schema 升级链集中在 database_schema.dart 维护
*- 提供 [sizeInBytes] / [clearAll] 两个全局能力
*通用 schema 包含一张 [cache_meta] 表,任何按 cache_key 走 TTL 的模块
*都通过 [CacheMetaDao] 共享它,避免每个 feature 各自维护 meta。
*/
class LocalDatabase {
  LocalDatabase._(this._db, this.path);

  final Database _db;
  final String path;

  // 当前 schema 版本。每次新增迁移在 database_schema.dart 的迁移链末尾追加并自增此值。
  static const int _kCurrentVersion = 7;

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
      options: OpenDatabaseOptions(version: _kCurrentVersion, onCreate: bootstrapSchema, onUpgrade: onUpgradeSchema),
    );
    return LocalDatabase._(db, dbPath);
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
      options: OpenDatabaseOptions(version: _kCurrentVersion, onCreate: bootstrapSchema, onUpgrade: onUpgradeSchema),
    );
    return LocalDatabase._(db, name);
  }

  /*
  *当前 DB 文件大小(字节)。失败时返回 0。
  */
  int sizeInBytes() {
    try {
      final f = File(path);
      if (!f.existsSync()) {
        return 0;
      }
      return f.lengthSync();
    } catch (_) {
      AppLogger.warn('database.sizeFailed', meta: {'op': 'stat'});
      return 0;
    }
  }

  /*
  *仅收录「可再生、不含用户状态」的远端快照缓存表。
  *ai_news_state / ai_news_reminder / ai_news_feedback / monitor_alert_event
  *属于用户数据,ai_news_enrichment 是可离线阅读的持久增强结果,
  *均不得加入此清单。只有新增可再生缓存表时才在这里追加一行。
  */
  static const List<String> _kClearableCacheTables = ['ai_news_item', 'trending_snapshot_cache', 'json_snapshot_cache', 'cache_meta'];

  /*
  *清空可再生的缓存表 + VACUUM。
  *遍历 [_kClearableCacheTables] 逐表 DELETE,不直接 DROP 以保留 schema,
  *清理后立刻可以重新写入。
  */
  Future<void> clearAll() async {
    try {
      for (final table in _kClearableCacheTables) {
        await _db.delete(table);
      }
      await _db.execute('VACUUM');
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'clearAll'});
    }
  }

  /*
  *历史兼容入口:项目当前不设置自动容量上限,因此这里保持 no-op。
  *手动清理仍走 [clearAll]。
  */
  Future<void> enforceCap() async {
    return;
  }

  /* 
  *关闭底层连接。生产环境由 OS 回收,主要用于测试 tearDown。
  */
  Future<void> close() => _db.close();
}
