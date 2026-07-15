import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_feedback.dart';

class AiNewsFeedbackDao {
  const AiNewsFeedbackDao(this._db);

  final DatabaseExecutor _db;

  Future<List<AiNewsFeedbackEntry>> readAll() async {
    try {
      final rows = await _db.query(
        'ai_news_feedback',
        orderBy: 'updated_at DESC',
      );
      return rows.map(_fromRow).toList(growable: false);
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': 'readAiNewsFeedback'},
      );
    }
  }

  Future<void> set(AiNewsFeedbackEntry entry) async {
    try {
      await _db.insert(
        'ai_news_feedback',
        {
          'item_id': entry.itemId,
          'signal': entry.signal.value,
          'topic_key': entry.topicKey,
          'updated_at': entry.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': 'setAiNewsFeedback'},
      );
    }
  }

  Future<void> remove(String itemId) async {
    try {
      await _db.delete(
        'ai_news_feedback',
        where: 'item_id = ?',
        whereArgs: [itemId],
      );
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': 'removeAiNewsFeedback'},
      );
    }
  }

  static AiNewsFeedbackEntry _fromRow(Map<String, Object?> row) {
    return AiNewsFeedbackEntry(
      itemId: row['item_id'] as String,
      signal: AiNewsFeedbackSignal.fromValue(row['signal'] as int)!,
      topicKey: row['topic_key'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}
