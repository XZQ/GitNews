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
    author        TEXT NOT NULL DEFAULT '',
    content       TEXT NOT NULL DEFAULT '',
    attribution_source TEXT NOT NULL DEFAULT '',
    updated_at    INTEGER NOT NULL,
    ext1          TEXT,
    ext2          INTEGER
  )
''';

// AI 资讯全文索引。使用独立 FTS5 表和触发器同步 ai_news_item，避免业务
// DAO 手动维护两份写入逻辑；迁移时会为已有条目补建索引。
const String _kCreateAiNewsFts = '''
  CREATE VIRTUAL TABLE IF NOT EXISTS ai_news_fts USING fts5(
    item_id UNINDEXED,
    title,
    title_en,
    summary,
    source,
    tokenize = 'unicode61'
  )
''';

const List<String> _kCreateAiNewsFtsTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS ai_news_fts_insert AFTER INSERT ON ai_news_item
    BEGIN
      DELETE FROM ai_news_fts WHERE item_id = new.id;
      INSERT INTO ai_news_fts(item_id, title, title_en, summary, source)
      VALUES (new.id, new.title, new.title_en, new.summary, new.source);
    END
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS ai_news_fts_update AFTER UPDATE ON ai_news_item
    BEGIN
      DELETE FROM ai_news_fts WHERE item_id = old.id OR item_id = new.id;
      INSERT INTO ai_news_fts(item_id, title, title_en, summary, source)
      VALUES (new.id, new.title, new.title_en, new.summary, new.source);
    END
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS ai_news_fts_delete AFTER DELETE ON ai_news_item
    BEGIN
      DELETE FROM ai_news_fts WHERE item_id = old.id;
    END
  ''',
];

// 逐条 LLM 增强结果。原文不被覆盖，结果按条目和模型持久缓存。
const String _kCreateAiNewsEnrichment = '''
  CREATE TABLE IF NOT EXISTS ai_news_enrichment (
    item_id             TEXT PRIMARY KEY,
    generated_summary   TEXT NOT NULL,
    translated_title    TEXT NOT NULL,
    translated_summary  TEXT NOT NULL,
    importance_score    REAL NOT NULL,
    entities_json       TEXT NOT NULL,
    model               TEXT NOT NULL,
    updated_at          INTEGER NOT NULL
  )
''';

// 本地兴趣反馈。signal=-1 表示减少此类，signal=1 表示更多此类。
const String _kCreateAiNewsFeedback = '''
  CREATE TABLE IF NOT EXISTS ai_news_feedback (
    item_id      TEXT PRIMARY KEY,
    signal       INTEGER NOT NULL CHECK(signal IN (-1, 1)),
    topic_key    TEXT NOT NULL,
    updated_at   INTEGER NOT NULL
  )
''';

// 后台刷新发现的新资讯提醒。提醒已读状态属于用户数据，不随缓存清理。
const String _kCreateAiNewsReminder = '''
  CREATE TABLE IF NOT EXISTS ai_news_reminder (
    item_id       TEXT PRIMARY KEY,
    title         TEXT NOT NULL,
    source        TEXT NOT NULL,
    published_at  INTEGER NOT NULL,
    created_at    INTEGER NOT NULL,
    read_at       INTEGER
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
      author        TEXT NOT NULL DEFAULT '',
      content       TEXT NOT NULL DEFAULT '',
      attribution_source TEXT NOT NULL DEFAULT '',
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
  'CREATE INDEX IF NOT EXISTS idx_ai_news_state_read_later ON ai_news_state(read_later_at)',
  _kCreateAiNewsFts,
  ..._kCreateAiNewsFtsTriggers,
  _kCreateAiNewsEnrichment,
  _kCreateAiNewsFeedback,
  'CREATE INDEX IF NOT EXISTS idx_ai_news_feedback_topic ON ai_news_feedback(topic_key, signal)',
  _kCreateAiNewsReminder,
  'CREATE INDEX IF NOT EXISTS idx_ai_news_reminder_created ON ai_news_reminder(created_at DESC)',
  'CREATE INDEX IF NOT EXISTS idx_ai_news_reminder_read ON ai_news_reminder(read_at)'
];

// 版本 N → N+1 的迁移函数列表。索引 0 = v0→v1。
// 初始 schema 通过 [_kBootstrap] 一次性创建。后续新增字段:
// ```dart
// (db) async => await db.execute('ALTER TABLE ai_news_item ADD COLUMN ext6 TEXT'),
// ```
const List<Future<void> Function(DatabaseExecutor)> _kMigrations = [
  _migrateV1ToV2,
  _migrateV2ToV3,
  _migrateV3ToV4,
  _migrateV4ToV5,
  _migrateV5ToV6,
  _migrateV6ToV7,
];

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

Future<void> _migrateV5ToV6(DatabaseExecutor db) async {
  await db.execute(_kCreateAiNewsFts);
  for (final statement in _kCreateAiNewsFtsTriggers) {
    await db.execute(statement);
  }
  await db.execute('DELETE FROM ai_news_fts');
  await db.execute(
    'INSERT INTO ai_news_fts(item_id, title, title_en, summary, source) '
    'SELECT id, title, title_en, summary, source FROM ai_news_item',
  );
  await db.execute(_kCreateAiNewsEnrichment);
  await db.execute(_kCreateAiNewsFeedback);
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_ai_news_feedback_topic '
    'ON ai_news_feedback(topic_key, signal)',
  );
  await db.execute(_kCreateAiNewsReminder);
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_ai_news_reminder_created '
    'ON ai_news_reminder(created_at DESC)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_ai_news_reminder_read '
    'ON ai_news_reminder(read_at)',
  );
}

Future<void> _migrateV6ToV7(DatabaseExecutor db) async {
  await _addColumnIfMissing(db, 'ai_news_item', 'author', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'ai_news_item', 'content', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'ai_news_item', 'attribution_source', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'ai_news_state', 'author', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'ai_news_state', 'content', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'ai_news_state', 'attribution_source', "TEXT NOT NULL DEFAULT ''");
}

/* 为兼容新建表与历史表的交叉路径,仅在列缺失时执行 ALTER TABLE。 */
Future<void> _addColumnIfMissing(DatabaseExecutor db, String table, String column, String definition) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  if (columns.any((entry) => entry['name'] == column)) {
    return;
  }
  await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
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
