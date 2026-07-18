import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_enrichment_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_enrichment.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_action_bar.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_content.dart';

Future<ThemeData>? _goldenThemeFuture;

class _StaticAiDigestConfigController extends AiDigestConfigController {
  @override
  AiDigestConfigState build() => const AiDigestConfigState();
}

void main() {
  testWidgets('captures the top of the single-page article detail', (
    tester,
  ) async {
    await _setViewport(tester, const Size(942, 1670));
    final item = _item();
    final theme = await tester.runAsync(_goldenTheme);
    await tester.pumpWidget(_visualApp(item, theme!));
    await _precacheDetailAssets(tester);

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    if (Platform.isWindows) {
      await expectLater(
        find.byKey(const ValueKey('ai-news-detail-visual')),
        matchesGoldenFile('goldens/ai_news_detail_single_page_top.png'),
      );
    }
  });

  testWidgets('captures the vertically scrolled continuation', (tester) async {
    await _setViewport(tester, const Size(942, 1670));
    final item = _item();
    final theme = await tester.runAsync(_goldenTheme);
    await tester.pumpWidget(_visualApp(item, theme!));
    await _precacheDetailAssets(tester);
    await tester.dragUntilVisible(
      find.text('相关文章'),
      find.byType(SingleChildScrollView),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();

    expect(find.text('相关文章').hitTestable(), findsOneWidget);
    if (Platform.isWindows) {
      await expectLater(
        find.byKey(const ValueKey('ai-news-detail-visual')),
        matchesGoldenFile('goldens/ai_news_detail_single_page_scrolled.png'),
      );
    }
  });

  testWidgets('captures compact Chinese article detail without overflow', (
    tester,
  ) async {
    await _setViewport(tester, const Size(750, 1692));
    final item = _chineseItem();
    final theme = await tester.runAsync(_goldenTheme);
    await tester.pumpWidget(
      _visualApp(
        item,
        theme!,
        feedbackSignal: AiNewsFeedbackSignal.more,
        itemState: AiNewsItemState(
          readLaterAt: DateTime(2026, 7, 17),
        ),
      ),
    );
    await _precacheDetailAssets(tester);

    expect(find.text('英文原文'), findsNothing);
    expect(find.text('中文翻译'), findsNothing);
    expect(tester.takeException(), isNull);
    if (Platform.isWindows) {
      await expectLater(
        find.byKey(const ValueKey('ai-news-detail-visual')),
        matchesGoldenFile('goldens/ai_news_detail_page_compact_chinese.png'),
      );
    }
  });
}

Widget _visualApp(
  AiNewsItem item,
  ThemeData theme, {
  AiNewsFeedbackSignal? feedbackSignal,
  AiNewsItemState itemState = AiNewsItemState.none,
}) {
  return ProviderScope(
    overrides: [
      aiNewsInterestProfileProvider.overrideWith(
        (ref) async => feedbackSignal == null
            ? AiNewsInterestProfile.empty
            : AiNewsInterestProfile(
                itemSignals: {item.id: feedbackSignal},
                topicWeights: const {},
              ),
      ),
      aiNewsItemStateProvider(item.id).overrideWith((ref) async => itemState),
      aiDigestConfigControllerProvider.overrideWith(_StaticAiDigestConfigController.new),
      aiNewsEnrichmentProvider.overrideWith((ref, itemId) async => _enrichment(itemId)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return RepaintBoundary(
            key: const ValueKey('ai-news-detail-visual'),
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                leading: const BackButton(),
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(l10n.tr('ai_news.detail_title')),
                actions: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
                ],
              ),
              body: AiNewsDetailContent(
                item: item,
                relatedItems: _relatedItems(),
              ),
              bottomNavigationBar: AiNewsDetailActionBar(item: item, onShare: () {}),
            ),
          );
        },
      ),
    ),
  );
}

/* 设置金图视口并在测试结束时恢复。 */
Future<void> _setViewport(WidgetTester tester, Size physicalSize) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/* 预缓存单页详情首屏与下方推荐区使用的全部图片。 */
Future<void> _precacheDetailAssets(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    final imageContext = tester.element(
      find.byKey(const ValueKey('ai-news-detail-visual')),
    );
    for (final path in [
      'assets/ai_news/detail_memory_sync_hero.png',
      'assets/ai_news/article_neural.png',
      'assets/ai_news/article_document.png',
      'assets/ai_news/article_city.png',
    ]) {
      await precacheImage(AssetImage(path), imageContext);
    }
  });
  await tester.pumpAndSettle();
}

AiNewsEnrichment _enrichment(String itemId) {
  return AiNewsEnrichment(
    itemId: itemId,
    generatedSummary: '通过 SSH 在多端之间安全同步智能体内存，帮助 AI 编程智能体在不同会话与设备间保持连续、稳定的上下文。',
    translatedTitle: '开源编程智能体内存方案发布，通过 SSH 同步',
    translatedSummary: '开源、可自托管并仅依赖通用协议，兼顾数据主权与开发者体验，是当前 AI Coding 工具链的重要基础设施。',
    importanceScore: 76,
    entities: const AiNewsEntities(
      models: ['AI Agent', 'Memory'],
      repositories: ['SSH', 'Open Source', 'Self-hosted'],
    ),
    model: 'local-preview',
    updatedAt: DateTime(2026, 7, 16, 7),
  );
}

Future<ThemeData> _goldenTheme() async {
  return _goldenThemeFuture ??= _loadGoldenTheme();
}

Future<ThemeData> _loadGoldenTheme() async {
  if (!Platform.isWindows) {
    return AppTheme.light(AppColors.brand);
  }
  final cjkBytes = await File('C:/Windows/Fonts/simhei.ttf').readAsBytes();
  final iconBytes = await File('D:/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes();
  final cjkLoader = FontLoader('AiNewsDetailGoldenFont')..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(cjkBytes))));
  final iconLoader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(iconBytes))));
  await Future.wait([cjkLoader.load(), iconLoader.load()]);
  final baseTheme = AppTheme.light(AppColors.brand);
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'AiNewsDetailGoldenFont'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'AiNewsDetailGoldenFont'),
    appBarTheme: baseTheme.appBarTheme.copyWith(
      titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'AiNewsDetailGoldenFont'),
    ),
    textButtonTheme: TextButtonThemeData(
      style: baseTheme.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(baseTheme.textTheme.labelLarge?.copyWith(fontFamily: 'AiNewsDetailGoldenFont')),
      ),
    ),
  );
}

AiNewsItem _item() {
  return AiNewsItem(
    id: 'visual-detail',
    category: AiNewsCategory.aiProducts,
    title: '开源编程智能体内存方案发布，通过 SSH 同步',
    titleEn: 'An open-source memory system for AI coding agents is now available on GitHub, enabling memory persistence and synchronization via SSH.',
    summary: '一个面向编程 AI 智能体的开源内存项目在 GitHub 发布，支持通过 SSH 同步记忆数据。该项目允许智能体跨会话保留上下文，无需依赖特定云服务，用户可自托管。',
    source: 'Hacker News · buzzing.cc 中文翻译',
    url: 'https://github.com/example/memory',
    permalink: 'https://example.com/article',
    publishedAt: DateTime(2026, 7, 16, 6, 49),
    score: 76,
    selected: true,
  );
}

AiNewsItem _chineseItem() {
  return AiNewsItem(
    id: 'visual-chinese-detail',
    category: AiNewsCategory.industry,
    title: '世界人工智能合作组织协定签署仪式在上海举行，总部设在中国上海',
    titleEn: '世界人工智能合作组织协定签署仪式在上海举行，总部设在中国上海',
    summary: '7月16日，成立世界人工智能合作组织协定签署仪式在上海举行。该组织是独立的政府间国际组织，总部设在中国上海。',
    source: 'IT之家（RSS）',
    url: 'https://example.com/chinese-article',
    permalink: 'https://example.com/chinese-article',
    publishedAt: DateTime(2026, 7, 16, 22, 38),
    score: 75,
    selected: true,
  );
}

List<AiNewsItem> _relatedItems() {
  const titles = ['Mem0：为 LLM 提供持久化内存的开源方案', 'SSH 最佳实践：密钥管理与安全加固指南', 'AI 代理的记忆架构演进：从短期到跨会话'];
  return [
    for (var index = 0; index < titles.length; index++)
      AiNewsItem(
        id: 'related-$index',
        category: index == 2 ? AiNewsCategory.aiProducts : AiNewsCategory.tip,
        title: titles[index],
        titleEn: titles[index],
        summary: '探索 AI 应用如何在会话间保持长期记忆与上下文。',
        source: 'GitHub',
        url: 'https://example.com/related-$index',
        permalink: 'https://example.com/related-$index',
        publishedAt: DateTime(2026, 7, 15 - index),
        score: 70 - index,
        selected: false,
      ),
  ];
}
