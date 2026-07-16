import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('related items prioritize the current category before score', () {
    final current = _item('current', AiNewsCategory.aiProducts, 90, 0);
    final result = selectRelatedAiNewsItems(
      [
        current,
        _item('other-hot', AiNewsCategory.industry, 99, 3),
        _item('same-low', AiNewsCategory.aiProducts, 40, 2),
        _item('same-high', AiNewsCategory.aiProducts, 80, 1),
        _item('other-mid', AiNewsCategory.tip, 70, 4),
      ],
      current: current,
      limit: 3,
    );

    expect(result.map((item) => item.id), [
      'same-high',
      'same-low',
      'other-hot',
    ]);
  });
}

AiNewsItem _item(String id, AiNewsCategory category, int score, int dayOffset) {
  return AiNewsItem(
    id: id,
    category: category,
    title: id,
    titleEn: id,
    summary: id,
    source: 'source',
    url: 'https://example.com/$id',
    permalink: 'https://example.com/$id',
    publishedAt: DateTime(2026, 7, 16).subtract(Duration(days: dayOffset)),
    score: score,
    selected: false,
  );
}
