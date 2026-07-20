import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/preferences/ai_digest_config_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/ai_news_enrichment_dao.dart';
import '../domain/ai_news_enrichment.dart';
import '../domain/ai_news_item.dart';
import 'ai_digest_providers.dart';
import 'ai_news_providers.dart';

final aiNewsEnrichmentDaoProvider = Provider<AiNewsEnrichmentDao>((ref) => AiNewsEnrichmentDao(ref.watch(appDatabaseProvider).executor));

final aiNewsEnrichmentProvider = FutureProvider.autoDispose.family<AiNewsEnrichment?, String>((ref, itemId) async {
  final cached = await ref.watch(aiNewsEnrichmentDaoProvider).read(itemId);
  return cached?.model == ApiEndpointsConfig.aiDigestDefaultModel ? cached : null;
});

final aiNewsEnrichmentControllerProvider = Provider<AiNewsEnrichmentController>(AiNewsEnrichmentController.new);

/*
*单条资讯增强生成函数,供详情页触发并允许测试替换副作用边界。
*/
typedef AiNewsEnrichmentGenerator = Future<AiNewsEnrichment?> Function(AiNewsItem item, {bool force});

final aiNewsEnrichmentGeneratorProvider = Provider<AiNewsEnrichmentGenerator>((ref) => ref.watch(aiNewsEnrichmentControllerProvider).enrich);

class AiNewsEnrichmentController {
  const AiNewsEnrichmentController(this._ref);

  final Ref _ref;

  Future<AiNewsEnrichment?> enrich(AiNewsItem item, {bool force = false}) async {
    final dao = _ref.read(aiNewsEnrichmentDaoProvider);
    if (!force) {
      final cached = await dao.read(item.id);
      if (cached?.model == ApiEndpointsConfig.aiDigestDefaultModel) {
        return cached;
      }
    }
    final config = _ref.read(aiDigestConfigControllerProvider);
    if (!config.configured) {
      return null;
    }
    final raw = await _ref.read(aiDigestLlmClientProvider).complete(apiKey: config.apiKey!, systemPrompt: _systemPrompt, userPrompt: _prompt(item));
    final enrichment = parseAiNewsEnrichment(raw, itemId: item.id, model: ApiEndpointsConfig.aiDigestDefaultModel, now: _ref.read(clockProvider)());
    await dao.upsert(enrichment);
    _ref.invalidate(aiNewsEnrichmentProvider(item.id));
    return enrichment;
  }

  static const _systemPrompt =
      '你是 AI 资讯编辑。只输出一个 JSON 对象，不要 Markdown。字段必须是:'
      'generated_summary(不超过120字的中文摘要)、translated_title(中文标题)、'
      'translated_summary(中文翻译)、importance_score(0到100数字)、entities。'
      'entities 必须含 models、companies、repositories 三个字符串数组。只依据原文。';

  static String _prompt(AiNewsItem item) =>
      '''
title: ${item.title}
title_en: ${item.titleEn}
summary: ${item.summary}
source: ${item.source}
url: ${item.url}
''';
}

AiNewsEnrichment parseAiNewsEnrichment(String raw, {required String itemId, required String model, required DateTime now}) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('LLM enrichment must be a JSON object');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) {
    throw const FormatException('LLM enrichment must be a JSON object');
  }
  final json = decoded.cast<String, Object?>();
  final rawEntities = json['entities'];
  final entities = rawEntities is Map ? rawEntities.cast<String, Object?>() : const <String, Object?>{};
  return AiNewsEnrichment(
    itemId: itemId,
    generatedSummary: _requiredText(json, 'generated_summary'),
    translatedTitle: _requiredText(json, 'translated_title'),
    translatedSummary: _requiredText(json, 'translated_summary'),
    importanceScore: _score(json['importance_score']),
    entities: AiNewsEntities(models: _stringList(entities['models']), companies: _stringList(entities['companies']), repositories: _stringList(entities['repositories'])),
    model: model,
    updatedAt: now.toUtc(),
  );
}

String _requiredText(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing enrichment field: $key');
  }
  return value.trim();
}

double _score(Object? raw) {
  if (raw is! num) {
    throw const FormatException('Invalid importance score');
  }
  return raw.toDouble().clamp(0, 100);
}

List<String> _stringList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw.whereType<String>().map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList(growable: false);
}
