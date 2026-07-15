import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_enrichment.dart';

class AiNewsEnrichmentDao {
  const AiNewsEnrichmentDao(this._db);

  final DatabaseExecutor _db;

  Future<AiNewsEnrichment?> read(String itemId) async {
    try {
      final rows = await _db.query(
        'ai_news_enrichment',
        where: 'item_id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      return rows.isEmpty ? null : _fromRow(rows.first);
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': 'readAiNewsEnrichment'},
      );
    }
  }

  Future<void> upsert(AiNewsEnrichment enrichment) async {
    try {
      await _db.insert(
        'ai_news_enrichment',
        {
          'item_id': enrichment.itemId,
          'generated_summary': enrichment.generatedSummary,
          'translated_title': enrichment.translatedTitle,
          'translated_summary': enrichment.translatedSummary,
          'importance_score': enrichment.importanceScore,
          'entities_json': jsonEncode({
            'models': enrichment.entities.models,
            'companies': enrichment.entities.companies,
            'repositories': enrichment.entities.repositories,
          }),
          'model': enrichment.model,
          'updated_at': enrichment.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': 'upsertAiNewsEnrichment'},
      );
    }
  }

  static AiNewsEnrichment _fromRow(Map<String, Object?> row) {
    final rawEntities = jsonDecode(row['entities_json'] as String);
    final entities = rawEntities is Map ? rawEntities.cast<String, Object?>() : const <String, Object?>{};
    return AiNewsEnrichment(
      itemId: row['item_id'] as String,
      generatedSummary: row['generated_summary'] as String,
      translatedTitle: row['translated_title'] as String,
      translatedSummary: row['translated_summary'] as String,
      importanceScore: (row['importance_score'] as num).toDouble(),
      entities: AiNewsEntities(
        models: _strings(entities['models']),
        companies: _strings(entities['companies']),
        repositories: _strings(entities['repositories']),
      ),
      model: row['model'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }

  static List<String> _strings(Object? raw) {
    return raw is List ? raw.whereType<String>().map((value) => value.trim()).where((value) => value.isNotEmpty).toList() : const [];
  }
}
