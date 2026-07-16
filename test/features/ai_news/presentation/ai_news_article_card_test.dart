import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_timeline_row.dart';
import 'package:github_news/shared/widgets/app_card.dart';

void main() {
  testWidgets('AI 资讯条目在移动宽度下使用日报同款卡片背景', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = AiNewsItem(
      id: 'card-test',
      category: AiNewsCategory.aiModels,
      title: 'AI 资讯列表恢复清晰的卡片背景',
      titleEn: 'AI news list restores a clear card surface',
      summary: '标题、摘要、来源和评分仍保持紧凑层级。',
      source: '测试来源',
      publishedAt: DateTime(2026, 7, 16, 12),
      score: 72,
      selected: true,
      url: 'https://example.com/article',
      permalink: 'https://example.com/article',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none)],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AiNewsTimelineRow(item: item, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.text(item.title), findsOneWidget);
    expect(find.text(item.summary), findsOneWidget);
  });
}
