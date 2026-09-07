import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_item_list.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_timeline_row.dart';

void main() {
  testWidgets('interest changes reorder clustered events but switching to search restores input order', (tester) async {
    final items = [
      AiNewsItem(
        id: 'newest',
        category: AiNewsCategory.industry,
        title: 'Robots learn dexterous manipulation',
        titleEn: '',
        summary: '',
        source: 'Robotics',
        url: '',
        permalink: '',
        publishedAt: DateTime(2026, 9, 7, 12),
        score: 99,
        selected: true,
      ),
      AiNewsItem(
        id: 'older',
        category: AiNewsCategory.aiModels,
        title: 'Language benchmark tests long context',
        titleEn: '',
        summary: '',
        source: 'Models',
        url: '',
        permalink: '',
        publishedAt: DateTime(2026, 9, 7, 10),
        score: 70,
        selected: true,
      ),
    ];
    var profile = AiNewsInterestProfile.empty;
    final container = ProviderContainer(overrides: [aiNewsInterestProfileProvider.overrideWith((ref) async => profile), aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none)]);
    addTearDown(container.dispose);
    Widget app({bool search = false}) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: AiNewsItemList(items: items, category: null, query: '', staticList: true, searchResults: search),
        ),
      ),
    );
    Iterable<String> ids() => tester.widgetList<AiNewsTimelineRow>(find.byType(AiNewsTimelineRow)).map((row) => row.item.id);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(ids(), ['newest', 'older']);
    profile = const AiNewsInterestProfile(itemSignals: {'newest': AiNewsFeedbackSignal.less, 'older': AiNewsFeedbackSignal.more});
    container.invalidate(aiNewsInterestProfileProvider);
    await tester.pumpAndSettle();
    expect(ids(), ['older', 'newest']);
    await tester.pumpWidget(app(search: true));
    await tester.pumpAndSettle();
    expect(ids(), ['newest', 'older']);
  });

  testWidgets('search keeps each hit accessible in database order despite similar titles', (tester) async {
    final items = [
      for (final id in ['second', 'first'])
        AiNewsItem(
          id: id,
          category: AiNewsCategory.aiModels,
          title: '人工智能模型发布',
          titleEn: 'A model release',
          summary: '',
          source: id,
          url: 'https://example.com/$id',
          permalink: '',
          publishedAt: DateTime.utc(2026, 7, 1),
          score: id == 'first' ? 100 : 1,
          selected: true,
        ),
    ];
    var moreCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiNewsInterestProfileProvider.overrideWith((ref) async => AiNewsInterestProfile.empty), aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none)],
        child: MaterialApp(
          home: Scaffold(
            body: AiNewsItemList(
              items: items,
              category: null,
              query: '模型',
              staticList: true,
              searchResults: true,
              pagingFooter: TextButton(onPressed: () => moreCalls++, child: const Text('Next page')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widgetList<AiNewsTimelineRow>(find.byType(AiNewsTimelineRow)).map((row) => row.item.id), ['second', 'first']);
    await tester.ensureVisible(find.text('Next page'));
    await tester.tap(find.text('Next page'));
    expect(moreCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
