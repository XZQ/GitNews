import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_content.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_language_switcher.dart';

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
      find.byType(AiNewsDetailLanguageSwitcher),
    );

    expect(languageCardRect.width, lessThanOrEqualTo(760));
    expect(languageCardRect.left, greaterThan(150));
    expect(languageCardRect.right, lessThan(1250));
  });

  testWidgets('article detail uses one continuous vertical reading flow', (
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

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('共 3 页'), findsNothing);

    await tester.dragUntilVisible(
      find.text('相关文章'),
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(find.text('相关文章').hitTestable(), findsOneWidget);
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

    await tester.dragUntilVisible(
      find.text('相关文章'),
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(find.text('相关文章').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Chinese articles hide duplicate original and translation cards',
    (tester) async {
      tester.view.physicalSize = const Size(375, 846);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(AiNewsDetailContent(item: _chineseItem(), showEnrichment: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('英文原文'), findsNothing);
      expect(find.text('中文翻译'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English articles show the original and Chinese translation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 846);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(AiNewsDetailContent(item: _item(), showEnrichment: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('EN · 英文原文'), findsOneWidget);
    expect(find.text('中 · 中文翻译'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bilingual selector switches between comparison and single language',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(AiNewsDetailContent(item: _item(), showEnrichment: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('EN · 英文原文'), findsOneWidget);
      expect(find.text('中 · 中文翻译'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ai-news-language-chinese')));
      await tester.pumpAndSettle();

      expect(find.text('EN · 英文原文'), findsNothing);
      expect(find.text('中 · 中文翻译'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AiNewsDetailLanguageSwitcher),
          matching: find.textContaining('一个面向编程 AI 智能体'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long Chinese titles do not overflow the compact hero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 846);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        AiNewsDetailContent(
          item: _chineseItem(title: '世界人工智能合作组织协定签署仪式在上海举行，总部设在中国上海并推动全球协作'),
          showEnrichment: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('世界人工智能合作组织协定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
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
    ),
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

AiNewsItem _chineseItem({String? title}) {
  return AiNewsItem(
    id: 'chinese-detail',
    category: AiNewsCategory.industry,
    title: title ?? '国务院推进人工智能全学段教育',
    titleEn: '国务院：推进人工智能全学段教育，提升学生人工智能素养',
    summary: '规划要求完善科学教育体系，强化科技教育与人文教育协同。',
    source: 'IT之家（RSS）',
    url: 'https://example.com/chinese',
    permalink: 'https://example.com/chinese',
    publishedAt: DateTime(2026, 7, 16, 22, 38),
    score: 75,
    selected: true,
  );
}
