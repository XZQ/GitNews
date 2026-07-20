import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_enrichment_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_enrichment_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_enrichment.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiNewsEnrichmentDao extends Mock implements AiNewsEnrichmentDao {}

void main() {
  test('parses fenced structured enrichment and clamps score', () {
    final now = DateTime.utc(2026, 7, 16);
    final result = parseAiNewsEnrichment(
      '''```json
      {
        "generated_summary": "中文摘要",
        "translated_title": "中文标题",
        "translated_summary": "中文翻译",
        "importance_score": 120,
        "entities": {
          "models": ["GPT-6"],
          "companies": ["OpenAI"],
          "repositories": ["openai/example"]
        }
      }
      ```''',
      itemId: 'item-1',
      model: 'model-x',
      now: now,
    );

    expect(result.itemId, 'item-1');
    expect(result.importanceScore, 100);
    expect(result.entities.all, ['GPT-6', 'OpenAI', 'openai/example']);
    expect(result.updatedAt, now);
  });

  test('missing required field is rejected', () {
    expect(() => parseAiNewsEnrichment('{"generated_summary":"x"}', itemId: 'item-1', model: 'model-x', now: DateTime.utc(2026)), throwsFormatException);
  });

  test('旧模型缓存不会显示为 Agnes 深度解读', () async {
    final dao = _MockAiNewsEnrichmentDao();
    when(() => dao.read('item-1')).thenAnswer((_) async => _enrichment(model: 'LongCat-2.0'));
    final container = ProviderContainer(overrides: [aiNewsEnrichmentDaoProvider.overrideWithValue(dao)]);
    addTearDown(container.dispose);

    expect(await container.read(aiNewsEnrichmentProvider('item-1').future), isNull);
  });

  test('当前 Agnes 模型缓存可以直接展示', () async {
    final dao = _MockAiNewsEnrichmentDao();
    final enrichment = _enrichment(model: 'agnes-2.0-flash');
    when(() => dao.read('item-1')).thenAnswer((_) async => enrichment);
    final container = ProviderContainer(overrides: [aiNewsEnrichmentDaoProvider.overrideWithValue(dao)]);
    addTearDown(container.dispose);

    expect(await container.read(aiNewsEnrichmentProvider('item-1').future), same(enrichment));
  });
}

/* 创建指定模型的缓存增强结果。 */
AiNewsEnrichment _enrichment({required String model}) {
  return AiNewsEnrichment(
    itemId: 'item-1',
    generatedSummary: '摘要',
    translatedTitle: '标题',
    translatedSummary: '翻译',
    importanceScore: 80,
    entities: const AiNewsEntities(),
    model: model,
    updatedAt: DateTime.utc(2026, 7, 20),
  );
}
