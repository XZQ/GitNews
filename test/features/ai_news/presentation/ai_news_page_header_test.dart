import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_page_header.dart';
import 'package:github_news/shared/widgets/header_search_field.dart';
import 'package:github_news/shared/widgets/page_header.dart';

void main() {
  testWidgets('AI 动态桌面页头不显示底部分隔线', (tester) async {
    tester.view.physicalSize = const Size(1200, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiNewsUnreadReminderCountProvider.overrideWithValue(0)],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(body: AiNewsPageHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageHeader = tester.widget<PageHeader>(find.byType(PageHeader));
    expect(pageHeader.showBottomDivider, isFalse);
    final container = tester.widget<Container>(find.descendant(of: find.byType(PageHeader), matching: find.byType(Container)).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNull);
  });

  testWidgets('AI 动态移动页头在 320px 宽度下完整展示且不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiNewsUnreadReminderCountProvider.overrideWithValue(0)],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(appBar: AiNewsCompactAppBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AiNewsCompactAppBar), findsOneWidget);
    expect(find.byType(AiNewsCompactSearchBar), findsOneWidget);
    expect(find.byType(PageHeader), findsNothing);
    expect(find.byType(HeaderSearchField), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    if (Platform.isWindows) {
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/ai_news_page_header_compact.png'));
    }
  });
}
