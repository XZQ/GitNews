import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_background_host.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('empty seen set establishes baseline without alerts', () {
    expect(
      detectNewAiNewsItems(
        [_item('new', DateTime.utc(2026, 7, 16))],
        seenIds: const {},
        now: DateTime.utc(2026, 7, 16),
      ),
      isEmpty,
    );
  });

  test('detects unseen recent items and ignores old or seen items', () {
    final now = DateTime.utc(2026, 7, 16, 12);
    final result = detectNewAiNewsItems(
      [
        _item('seen', now),
        _item('fresh', now.subtract(const Duration(hours: 2))),
        _item('old', now.subtract(const Duration(days: 3))),
      ],
      seenIds: const {'seen'},
      now: now,
    );

    expect(result.map((item) => item.id), ['fresh']);
  });
}

AiNewsItem _item(String id, DateTime publishedAt) {
  return AiNewsItem(
    id: id,
    category: AiNewsCategory.industry,
    title: id,
    titleEn: '',
    summary: '',
    source: 'source',
    url: '',
    permalink: '',
    publishedAt: publishedAt,
    score: 0,
    selected: false,
  );
}
