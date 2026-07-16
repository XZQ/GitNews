import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_components.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_content.dart';

void main() {
  testWidgets('article detail centers the reading column on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(AiNewsDetailContent(item: _item(), showEnrichment: false)),
    );
    await tester.pumpAndSettle();

    final languageCardRect = tester.getRect(
      find.byType(AiNewsDetailLanguageCard).first,
    );

    expect(languageCardRect.width, lessThanOrEqualTo(aiNewsDetailMaxWidth));
    expect(languageCardRect.left, greaterThan(150));
    expect(languageCardRect.right, lessThan(1250));
  });

  testWidgets('article detail swipes through all three reading pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(471, 835);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        AiNewsDetailContent(
          item: _item(),
          relatedItems: [_relatedItem('related-1'), _relatedItem('related-2')],
          showEnrichment: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第 1 页 / 共 3 页').hitTestable(), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.text('第 2 页 / 共 3 页').hitTestable(), findsOneWidget);
    expect(find.text('事件背景').hitTestable(), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.text('第 3 页 / 共 3 页').hitTestable(), findsOneWidget);
    expect(find.text('延伸解读').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article detail remains usable in a narrow dark viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        AiNewsDetailContent(
          item: _item(),
          relatedItems: [_relatedItem('related-dark')],
          showEnrichment: false,
        ),
        theme: AppTheme.dark(AppColors.brand),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();

    expect(find.text('延伸解读').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {ThemeData? theme}) {
  return MaterialApp(
    locale: const Locale('zh', 'CN'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    home: Scaffold(body: home),
  );
}

AiNewsItem _item() {
  return AiNewsItem(
    id: 'detail',
    category: AiNewsCategory.aiProducts,
    title: '开源编程智能体内存方案发布，通过 SSH 同步',
    titleEn: 'An open-source memory system for AI coding agents is now available on GitHub.',
    summary: '一个面向编程 AI 智能体的开源内存项目在 GitHub 发布，支持通过 SSH 同步记忆数据，并允许智能体跨会话保留上下文。',
    source: 'Hacker News · buzzing.cc 中文翻译',
    url: 'https://github.com/example/memory',
    permalink: 'https://example.com/article',
    publishedAt: DateTime(2026, 7, 16, 6, 49),
    score: 76,
    selected: true,
  );
}

AiNewsItem _relatedItem(String id) {
  return AiNewsItem(
    id: id,
    category: AiNewsCategory.tip,
    title: 'SSH 最佳实践与安全同步指南',
    titleEn: 'SSH synchronization guide',
    summary: '从密钥管理到权限控制，提升远程同步场景的安全性。',
    source: 'GitHub',
    url: 'https://example.com/$id',
    permalink: 'https://example.com/$id',
    publishedAt: DateTime(2026, 7, 15),
    score: 62,
    selected: false,
  );
}
