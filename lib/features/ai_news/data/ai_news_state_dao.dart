import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_item_state.dart';

/*
*AI 资讯用户状态 DAO(已读 / 稍后读)。
*每行同时保存条目实体快照,与收藏/监控的「真实实体快照」模式一致:
*缓存清空后稍后读列表仍可完整渲染。
*表由 database_schema.dart 的 v5 迁移创建;本表不属于可清理缓存。
*/
class AiNewsStateDao {
  AiNewsStateDao(this._db);

  final DatabaseExecutor _db;

  static const String _table = 'ai_news_state';

  /*
  *标记已读(幂等)。保留既有稍后读状态,同时刷新实体快照。
  */
  Future<void> markRead(AiNewsItem item, {required DateTime now}) async {
    try {
      final existing = await _rowOf(item.id);
      await _upsert(item, readAt: existing?['read_at'] as int? ?? now.millisecondsSinceEpoch, readLaterAt: existing?['read_later_at'] as int?, now: now);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'markRead'});
    }
  }

  /*
  *切换稍后读。返回切换后的状态(true = 已加入稍后读)。
  */
  Future<bool> toggleReadLater(AiNewsItem item, {required DateTime now}) async {
    try {
      final existing = await _rowOf(item.id);
      final wasReadLater = existing?['read_later_at'] != null;
      await _upsert(item, readAt: existing?['read_at'] as int?, readLaterAt: wasReadLater ? null : now.millisecondsSinceEpoch, now: now);
      return !wasReadLater;
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'toggleReadLater'});
    }
  }

  /*
  *查询单条状态;无记录返回 [AiNewsItemState.none]。
  */
  Future<AiNewsItemState> stateOf(String itemId) async {
    try {
      final row = await _rowOf(itemId);
      if (row == null) {
        return AiNewsItemState.none;
      }
      return AiNewsItemState(readAt: _time(row['read_at']), readLaterAt: _time(row['read_later_at']));
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'stateOf'});
    }
  }

  /*
  *稍后读列表(按加入时间倒序),从快照直接重建条目。
  */
  Future<List<AiNewsItem>> readLaterItems() async {
    try {
      final rows = await _db.query(_table, where: 'read_later_at IS NOT NULL', orderBy: 'read_later_at DESC');
      return rows.map(_rowToItem).toList(growable: false);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'readLaterItems'});
    }
  }

  /*
  *按 id 取实体快照(详情页兜底:条目缓存被清后,稍后读仍可渲染)。
  */
  Future<AiNewsItem?> snapshotOf(String itemId) async {
    try {
      final row = await _rowOf(itemId);
      return row == null ? null : _rowToItem(row);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'snapshotOf'});
    }
  }

  Future<Map<String, Object?>?> _rowOf(String itemId) async {
    final rows = await _db.query(_table, where: 'item_id = ?', whereArgs: [itemId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _upsert(AiNewsItem item, {required int? readAt, required int? readLaterAt, required DateTime now}) {
    return _db.insert(
      _table,
      {
        'item_id': item.id,
        'read_at': readAt,
        'read_later_at': readLaterAt,
        'category': item.category.code,
        'title': item.title,
        'title_en': item.titleEn,
        'summary': item.summary,
        'source': item.source,
        'url': item.url,
        'permalink': item.permalink,
        'published_at': item.publishedAt.millisecondsSinceEpoch,
        'score': item.score,
        'selected': item.selected ? 1 : 0,
        'updated_at': now.millisecondsSinceEpoch
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static DateTime? _time(Object? millis) {
    if (millis is! int) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  static AiNewsItem _rowToItem(Map<String, Object?> row) {
    return AiNewsItem(
      id: row['item_id'] as String,
      category: AiNewsCategory.fromCode(row['category'] as String?) ?? AiNewsCategory.industry,
      title: row['title'] as String,
      titleEn: row['title_en'] as String,
      summary: row['summary'] as String,
      source: row['source'] as String,
      url: row['url'] as String,
      permalink: row['permalink'] as String,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(row['published_at'] as int, isUtc: true),
      score: row['score'] as int,
      selected: (row['selected'] as int) == 1,
    );
  }
}
