import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_event_clustering.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('similar titles inside time window become one multi-source event', () {
    final items = [
      _item('a', 'OpenAI launches GPT 6 model today', 'Source A'),
      _item('b', 'OpenAI GPT 6 model launches today', 'Source B'),
      _item('c', 'New robotics funding round', 'Source C'),
    ];

    final clusters = clusterAiNewsEvents(items);

    expect(clusters, hasLength(2));
    final event = clusters.singleWhere((cluster) => cluster.items.length == 2);
    expect(event.sources.toSet(), {'Source A', 'Source B'});
  });

  test('same title outside time window remains separate', () {
    final first = _item('a', 'OpenAI launches GPT 6 model', 'A');
    final second = AiNewsItem(
      id: 'b',
      category: first.category,
      title: first.title,
      titleEn: '',
      summary: '',
      source: 'B',
      url: '',
      permalink: '',
      publishedAt: first.publishedAt.subtract(const Duration(days: 3)),
      score: 50,
      selected: false,
    );

    expect(clusterAiNewsEvents([first, second]), hasLength(2));
  });
}

AiNewsItem _item(String id, String title, String source) {
  return AiNewsItem(
    id: id,
    category: AiNewsCategory.aiModels,
    title: title,
    titleEn: '',
    summary: '',
    source: source,
    url: '',
    permalink: '',
    publishedAt: DateTime.utc(2026, 7, 16),
    score: 50,
    selected: false,
  );
}
