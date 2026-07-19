import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_reminder.dart';

class AiNewsReminderDao {
  const AiNewsReminderDao(this._db);

  final DatabaseExecutor _db;

  Future<void> addItems(List<AiNewsItem> items, {required DateTime now, String? languageCode}) async {
    try {
      final batch = _db.batch();
      for (final item in items) {
        batch.insert('ai_news_reminder', {
          'item_id': item.id,
          'title': item.titleForLanguage(languageCode),
          'source': item.source,
          'published_at': item.publishedAt.millisecondsSinceEpoch,
          'created_at': now.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (error, stack) {
      throw AppException(kind: AppExceptionKind.cache, cause: error, stack: stack, meta: {'op': 'addAiNewsReminders'});
    }
  }

  Future<List<AiNewsReminder>> readAll({int limit = 100}) async {
    try {
      final rows = await _db.query('ai_news_reminder', orderBy: 'created_at DESC', limit: limit);
      return rows.map(_fromRow).toList(growable: false);
    } catch (error, stack) {
      throw AppException(kind: AppExceptionKind.cache, cause: error, stack: stack, meta: {'op': 'readAiNewsReminders'});
    }
  }

  Future<void> markRead(String itemId, {required DateTime now}) async {
    await _updateRead(where: 'item_id = ?', whereArgs: [itemId], now: now);
  }

  Future<void> markAllRead({required DateTime now}) async {
    await _updateRead(where: 'read_at IS NULL', now: now);
  }

  Future<void> _updateRead({required String where, List<Object?>? whereArgs, required DateTime now}) async {
    try {
      await _db.update('ai_news_reminder', {'read_at': now.millisecondsSinceEpoch}, where: where, whereArgs: whereArgs);
    } catch (error, stack) {
      throw AppException(kind: AppExceptionKind.cache, cause: error, stack: stack, meta: {'op': 'readAiNewsReminder'});
    }
  }

  static AiNewsReminder _fromRow(Map<String, Object?> row) {
    DateTime time(String key) => DateTime.fromMillisecondsSinceEpoch(row[key] as int, isUtc: true);
    final readAt = row['read_at'];
    return AiNewsReminder(
      itemId: row['item_id'] as String,
      title: row['title'] as String,
      source: row['source'] as String,
      publishedAt: time('published_at'),
      createdAt: time('created_at'),
      readAt: readAt is int ? DateTime.fromMillisecondsSinceEpoch(readAt, isUtc: true) : null,
    );
  }
}
