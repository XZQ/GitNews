import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// SQLite 通用 schema 定义与迁移链。集中维护,避免 [LocalDatabase] 过长;
// 业务表创建走 [_kBootstrap],版本升级走 [_kMigrations]。

const String _kCreateCacheMeta = '''
  CREATE TABLE IF NOT EXISTS cache_meta (
    cache_key        TEXT PRIMARY KEY,
    last_fetched_at  INTEGER NOT NULL,
    payload_hash     TEXT,
    ext1             TEXT,
    ext2             INTEGER,
    ext3             REAL
  )
''';

const String _kCreateTrendingSnapshotCache = '''
  CREATE TABLE IF NOT EXISTS trending_snapshot_cache (
    cache_key     TEXT PRIMARY KEY,
    payload_json  TEXT NOT NULL,
    cached_at     INTEGER NOT NULL,
    ext1          TEXT,
    ext2          INTEGER,
    ext3          REAL
  )
''';

const String _kCreateJsonSnapshotCache = '''
  CREATE TABLE IF NOT EXISTS json_snapshot_cache (
    cache_key     TEXT PRIMARY KEY,
    payload_json  TEXT NOT NULL,
    cached_at     INTEGER NOT NULL,
    ext1          TEXT,
    ext2          INTEGER,
    ext3          REAL
  )
''';

const String _kCreateMonitorAlertEvent = '''
  CREATE TABLE IF NOT EXISTS monitor_alert_event (
    id              TEXT PRIMARY KEY,
    repo_full_name  TEXT NOT NULL,
    rule_id         TEXT NOT NULL,
    metric          TEXT NOT NULL,
    value           REAL NOT NULL,
    threshold       REAL NOT NULL,
    severity        TEXT NOT NULL,
    observed_at     INTEGER NOT NULL,
    read_at         INTEGER,
    archived_at     INTEGER
  )
''';

// AI 资讯用户状态:已读 / 稍后读 + 条目实体快照。
// 快照模式与收藏/监控一致:即使 ai_news_item 缓存被清空,
// 稍后读列表仍能凭快照完整渲染。不属于可清理缓存,不进业务表清单。
const String _kCreateAiNewsState = '''
  CREATE TABLE IF NOT EXISTS ai_news_state (
    item_id       TEXT PRIMARY KEY,
    read_at       INTEGER,
    read_later_at INTEGER,
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
    updated_at    INTEGER NOT NULL,
    ext1          TEXT,
    ext2          INTEGER
  )
''';

// 当前 schema 全部 DDL。新增表在这里追加,旧表结构变更走 [_kMigrations]。
const List<String> _kBootstrap = [
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
  _kCreateMonitorAlertEvent,
  'CREATE INDEX IF NOT EXISTS idx_monitor_alert_observed_at ON monitor_alert_event(observed_at)',
  'CREATE INDEX IF NOT EXISTS idx_monitor_alert_archived_at ON monitor_alert_event(archived_at)',
  'CREATE INDEX IF NOT EXISTS idx_monitor_alert_repo_rule ON monitor_alert_event(repo_full_name, rule_id)',
  _kCreateAiNewsState,
  'CREATE INDEX IF NOT EXISTS idx_ai_news_state_read_later ON ai_news_state(read_later_at)'
];

// 版本 N → N+1 的迁移函数列表。索引 0 = v0→v1。
// 初始 schema 通过 [_kBootstrap] 一次性创建。后续新增字段:
// ```dart
// (db) async => await db.execute('ALTER TABLE ai_news_item ADD COLUMN ext6 TEXT'),
// ```
const List<Future<void> Function(DatabaseExecutor)> _kMigrations = [_migrateV1ToV2, _migrateV2ToV3, _migrateV3ToV4, _migrateV4ToV5];

Future<void> _migrateV1ToV2(DatabaseExecutor db) async {
  await db.execute(_kCreateTrendingSnapshotCache);
  await db.execute('CREATE INDEX IF NOT EXISTS idx_trending_snapshot_cached_at ON trending_snapshot_cache(cached_at)');
}

Future<void> _migrateV2ToV3(DatabaseExecutor db) async {
  await db.execute(_kCreateJsonSnapshotCache);
  await db.execute('CREATE INDEX IF NOT EXISTS idx_json_snapshot_cached_at ON json_snapshot_cache(cached_at)');
}

Future<void> _migrateV3ToV4(DatabaseExecutor db) async {
  await db.execute(_kCreateMonitorAlertEvent);
  await db.execute('CREATE INDEX IF NOT EXISTS idx_monitor_alert_observed_at ON monitor_alert_event(observed_at)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_monitor_alert_archived_at ON monitor_alert_event(archived_at)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_monitor_alert_repo_rule ON monitor_alert_event(repo_full_name, rule_id)');
}

Future<void> _migrateV4ToV5(DatabaseExecutor db) async {
  await db.execute(_kCreateAiNewsState);
  await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_news_state_read_later ON ai_news_state(read_later_at)');
}

// 新建库时一次性创建全部业务表。
Future<void> bootstrapSchema(DatabaseExecutor db, _) async {
  for (final stmt in _kBootstrap) {
    await db.execute(stmt);
  }
}

// 旧版本库升级:逐版本执行对应迁移,直到目标版本。
Future<void> onUpgradeSchema(DatabaseExecutor db, int oldVersion, int newVersion) async {
  for (var v = oldVersion; v < newVersion && v <= _kMigrations.length; v++) {
    await _kMigrations[v - 1](db);
  }
}
