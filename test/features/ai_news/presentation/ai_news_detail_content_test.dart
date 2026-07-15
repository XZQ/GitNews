import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_content.dart';
import 'package:github_news/shared/widgets/app_card.dart';

void main() {
  testWidgets('article detail fills desktop width with 40px side gutters', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AiNewsDetailContent(item: _item()))));

    final summaryRect = tester.getRect(find.byType(AppCard).first);

    expect(summaryRect.left, greaterThanOrEqualTo(40));
    expect(summaryRect.right, lessThanOrEqualTo(1360));
    expect(summaryRect.width, greaterThan(1200));
  });
}

AiNewsItem _item() {
  return AiNewsItem(
    id: 'detail',
    category: AiNewsCategory.aiModels,
    title: 'AI detail title',
    titleEn: 'AI detail English title',
    summary: 'Summary content '.padRight(240, 'x'),
    source: 'Source',
    url: 'https://example.com/article',
    permalink: 'https://example.com/article',
    publishedAt: DateTime(2026, 7, 9, 10, 30),
    score: 88,
    selected: true,
  );
}
