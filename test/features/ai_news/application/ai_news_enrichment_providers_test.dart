import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_enrichment_providers.dart';

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
    expect(
      () => parseAiNewsEnrichment(
        '{"generated_summary":"x"}',
        itemId: 'item-1',
        model: 'model-x',
        now: DateTime.utc(2026),
      ),
      throwsFormatException,
    );
  });
}
