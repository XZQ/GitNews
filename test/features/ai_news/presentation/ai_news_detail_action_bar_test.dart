import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_action_bar.dart';

void main() {
  testWidgets('selected feedback and bookmark use the active theme color', (
    tester,
  ) async {
    final item = _item();
    tester.view.physicalSize = const Size(375, 846);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const brand = Color(0xFF7656D6);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsInterestProfileProvider.overrideWith(
            (ref) async => AiNewsInterestProfile(
              itemSignals: {item.id: AiNewsFeedbackSignal.more},
              topicWeights: const {},
            ),
          ),
          aiNewsItemStateProvider(item.id).overrideWith(
            (ref) async => AiNewsItemState(
              readLaterAt: DateTime(2026, 7, 17),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(brand),
          home: Scaffold(
            bottomNavigationBar: AiNewsDetailActionBar(
              item: item,
              onShare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final likedIcon = tester.widget<Icon>(
      find.byIcon(Icons.thumb_up_alt_rounded),
    );
    final savedIcon = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
    final selectedColor = Theme.of(
      tester.element(find.byIcon(Icons.thumb_up_alt_rounded)),
    ).colorScheme.primary;

    expect(find.text('赞 75'), findsOneWidget);
    expect(likedIcon.color, selectedColor);
    expect(savedIcon.color, selectedColor);
    expect(tester.takeException(), isNull);
  });
}

AiNewsItem _item() {
  return AiNewsItem(
    id: 'action-bar',
    category: AiNewsCategory.industry,
    title: '详情操作栏测试',
    titleEn: '',
    summary: '验证操作选中状态。',
    source: 'Test',
    url: 'https://example.com/action-bar',
    permalink: 'https://example.com/action-bar',
    publishedAt: DateTime(2026, 7, 17),
    score: 75,
    selected: false,
  );
}
