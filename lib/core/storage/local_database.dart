import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';

/// 数据库文件名。
const String kDatabaseFileName = 'github_news.db';

/// 1 GB 容量上限。
const int kMaxDatabaseBytes = 1 << 30; // 1024 * 1024 * 1024

/// 容量超限时,删除最旧条目的比例。
const double _kEvictRatio = 0.1;

/// 本地 SQLite 数据库封装。
///
/// 设计目标:
/// - 抽象掉 driver(sqflite_common_ffi),业务层只看到 [executor]
/// - 集中维护 schema 升级链([_kMigrations])
/// - 提供 [sizeInBytes] / [clearAll] / [enforceCap] 三个全局能力
///
/// 通用 schema 包含一张 [cache_meta] 表,任何按 cache_key 走 TTL 的模块
/// 都通过 [CacheMetaDao] 共享它,避免每个 feature 各自维护 meta。
class LocalDatabase {
  LocalDatabase._(this._db, this.path);

  final Database _db;
  final String path;

  /// 当前 schema 版本。每次新增迁移在 [_kMigrations] 末尾追加并自增此值。
  static const int _kCurrentVersion = 3;

  /// 业务方拿到这个 executor 后,在自己的 DAO 内执行 SQL。
  ///
  /// 故意返回 [DatabaseExecutor] 而不是 [Database],让 feature DAO
  /// 无法调用 `close()` / `setVersion` 等基础设施级 API。
  DatabaseExecutor get executor => _db;

  /// 启动入口:初始化 FFI、打开或创建数据库、跑迁移。
  ///
  /// 桌面端通过 `sqflite_common_ffi` 提供的 `databaseFactoryFfi` 走原生
  /// SQLite;移动端未来接入时同样能复用此实现(sqflite_common_ffi 在
  /// Android/iOS 同样可工作)。
  static Future<LocalDatabase> open() async {
    sqfliteFfiInit();
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, kDatabaseFileName);
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _kCurrentVersion,
        onCreate: _bootstrap,
        onUpgrade: _onUpgrade,
      ),
    );
    return LocalDatabase._(db, dbPath);
  }

  /// 仅用于测试:用 `:memory:` 打开,文件不落地。
  ///
  /// 每次 call 返回独立的内存库;`path` 字段对 `:memory:` 库无意义。
  static Future<LocalDatabase> openInMemory() async {
    sqfliteFfiInit();
    const name = ':memory:';
    final db = await databaseFactoryFfi.openDatabase(
      name,
      options: OpenDatabaseOptions(
        version: _kCurrentVersion,
        onCreate: _bootstrap,
        onUpgrade: _onUpgrade,
      ),
    );
    return LocalDatabase._(db, name);
  }

  static const String _kCreateCacheMeta = '''
    CREATE TABLE IF NOT EXISTS cache_meta (
      cache_key        TEXT PRIMARY KEY,
      last_fetched_at  INTEGER NOT NULL,
      payload_hash     TEXT,
      ext1             TEXT,
      ext2             INTEGER,
      ext3             REAL
    )
  ''';

  /// 当前 schema 全部 DDL。新增表在这里追加,旧表结构变更走 [_kMigrations]。
  static const List<String> _kBootstrap = [
    _kCreateCacheMeta,
    '''
      CREATE TABLE IF NOT EXISTS ai_news_item (
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
        cached_at     INTEGER NOT NULL,
        ext1          TEXT,
        ext2          TEXT,
        ext3          INTEGER,
        ext4          INTEGER,
        ext5          REAL
      )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_ai_news_cached_at ON ai_news_item(cached_at)',
    'CREATE INDEX IF NOT EXISTS idx_ai_news_category  ON ai_news_item(category)',
    _kCreateTrendingSnapshotCache,
    'CREATE INDEX IF NOT EXISTS idx_trending_snapshot_cached_at ON trending_snapshot_cache(cached_at)',
    _kCreateJsonSnapshotCache,
    'CREATE INDEX IF NOT EXISTS idx_json_snapshot_cached_at ON json_snapshot_cache(cached_at)',
  ];

  /// 版本 N → N+1 的迁移函数列表。索引 0 = v0→v1。
  ///
  /// 初始 schema 通过 [_kBootstrap] 一次性创建。后续新增字段:
  /// ```dart
  /// (db) async => await db.execute('ALTER TABLE ai_news_item ADD COLUMN ext6 TEXT'),
  /// ```
  static const List<Future<void> Function(DatabaseExecutor)> _kMigrations = [
    _migrateV1ToV2,
    _migrateV2ToV3,
  ];

  static const String _kCreateTrendingSnapshotCache = '''
    CREATE TABLE IF NOT EXISTS trending_snapshot_cache (
      cache_key     TEXT PRIMARY KEY,
      payload_json  TEXT NOT NULL,
      cached_at     INTEGER NOT NULL,
      ext1          TEXT,
      ext2          INTEGER,
      ext3          REAL
    )
  ''';

  static const String _kCreateJsonSnapshotCache = '''
    CREATE TABLE IF NOT EXISTS json_snapshot_cache (
      cache_key     TEXT PRIMARY KEY,
      payload_json  TEXT NOT NULL,
      cached_at     INTEGER NOT NULL,
      ext1          TEXT,
      ext2          INTEGER,
      ext3          REAL
    )
  ''';

  static Future<void> _migrateV1ToV2(DatabaseExecutor db) async {
    await db.execute(_kCreateTrendingSnapshotCache);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trending_snapshot_cached_at ON trending_snapshot_cache(cached_at)',
    );
  }

  static Future<void> _migrateV2ToV3(DatabaseExecutor db) async {
    await db.execute(_kCreateJsonSnapshotCache);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_json_snapshot_cached_at ON json_snapshot_cache(cached_at)',
    );
  }

  static Future<void> _bootstrap(DatabaseExecutor db, _) async {
    for (final stmt in _kBootstrap) {
      await db.execute(stmt);
    }
  }

  static Future<void> _onUpgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var v = oldVersion; v < newVersion && v <= _kMigrations.length; v++) {
      await _kMigrations[v - 1](db);
    }
  }

  /// 当前 DB 文件大小(字节)。失败时返回 0。
  int sizeInBytes() {
    try {
      final f = File(path);
      if (!f.existsSync()) return 0;
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  /// 清空所有业务表 + meta 表 + VACUUM。
  ///
  /// 通用清理入口:任何接入本基建的 feature 表都要在此处补一行 DELETE。
  /// 不直接 DROP 是为了保留 schema,清理后立刻可以重新写入。
  Future<void> clearAll() async {
    try {
      await _db.delete('ai_news_item');
      await _db.delete('trending_snapshot_cache');
      await _db.delete('json_snapshot_cache');
      await _db.delete('cache_meta');
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

  /// 容量守卫:超过 [kMaxDatabaseBytes] 时按 cached_at ASC 删旧 10%。
  ///
  /// 设计为「尽力而为」:在 [upsert] 完成后异步触发,失败只吞掉——
  /// 容量清理失败不应阻塞业务请求,下一轮再尝试。
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

  /// 关闭底层连接。生产环境由 OS 回收,主要用于测试 tearDown。
  Future<void> close() => _db.close();
}
