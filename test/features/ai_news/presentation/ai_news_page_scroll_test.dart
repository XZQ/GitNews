import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_digest_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/ai_news_page.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_category_nav.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_page_header.dart';

/*
*测试用静态资讯状态,避免滚动行为测试访问网络和本地数据库。
*/
class _StaticAiNewsItemsNotifier extends AiNewsItemsNotifier {
  _StaticAiNewsItemsNotifier(this._items);

  // 测试列表快照。
  final List<AiNewsItem> _items;

  /* 返回足以滚动的静态资讯列表。 */
  @override
  Future<List<AiNewsItem>> build() async => _items;

  @override
  bool get hasMore => false;

  /* 静态列表不加载下一页。 */
  @override
  Future<void> loadMore() async {}
}

/*
*测试用日报配置,固定为未配置态。
*/
class _StaticAiDigestConfigController extends AiDigestConfigController {
  /* 跳过安全存储读取。 */
  @override
  AiDigestConfigState build() => const AiDigestConfigState();
}

/*
*测试用日报内容,固定为空。
*/
class _StaticAiDigestNotifier extends AiDigestNotifier {
  /* 跳过偏好存储读取。 */
  @override
  Future<String?> build() async => null;
}

void main() {
  testWidgets('AI 标题栏固定且搜索框与分类横条随列表滚动', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 7, 16, 12);
    const titles = [
      'Learning Safe Agent Behaviour from Human Preferences',
      'Multi-Agent Collaborative Reasoning for Urban Regions',
      'Self-Improvements in Modern Agentic Systems: A Survey',
      'Probabilistic Extension of Neuro-Symbolic AGI',
      'Open Source Vision Model Reaches Mobile Devices',
      'New Evaluation Suite for Long Context Retrieval',
      'Robotics Foundation Model Learns from Video',
      'Efficient Local Inference on Consumer Hardware',
      'AI Coding Assistant Adds Repository Planning',
      'Synthetic Data Pipeline Improves Medical Models',
      'Benchmarking Reliable Tool Use in Production',
      'Small Language Models Gain Stronger Reasoning',
    ];
    final items = List.generate(
      12,
      (index) => AiNewsItem(
        id: 'scroll-$index',
        category: AiNewsCategory.paper,
        title: titles[index],
        titleEn: 'Independent AI topic $index',
        summary: '研究团队公布了新的方法、实验结果与可复现细节，为开发者提供清晰的技术参考。',
        source: 'arXiv cs.AI',
        publishedAt: now.subtract(Duration(minutes: index * 3)),
        score: 60 + index,
        selected: false,
        url: 'https://example.com/$index',
        permalink: 'https://example.com/$index',
      ),
    );

    if (Platform.isWindows) {
      await tester.runAsync(_loadWindowsCjkFont);
    }
    final baseTheme = AppTheme.light(AppColors.brand);
    final testTheme = Platform.isWindows
        ? baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'AiNewsGoldenFont'),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'AiNewsGoldenFont'),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'AiNewsGoldenFont'),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: baseTheme.filledButtonTheme.style?.copyWith(
                textStyle: WidgetStatePropertyAll(baseTheme.textTheme.labelLarge?.copyWith(fontFamily: 'AiNewsGoldenFont')),
              ),
            ),
          )
        : baseTheme;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsItemsNotifierProvider.overrideWith(() => _StaticAiNewsItemsNotifier(items)),
          aiNewsFreshnessProvider.overrideWith((ref) => DataFreshness.freshCache),
          aiNewsUnreadReminderCountProvider.overrideWithValue(0),
          aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none),
          aiDigestConfigControllerProvider.overrideWith(_StaticAiDigestConfigController.new),
          aiDigestNotifierProvider.overrideWith(_StaticAiDigestNotifier.new),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme,
          home: const AiNewsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBarFinder = find.byType(AiNewsCompactAppBar, skipOffstage: false);
    final searchFinder = find.byType(AiNewsCompactSearchBar, skipOffstage: false);
    final categoryFinder = find.byType(AiNewsCategoryNav, skipOffstage: false);
    final appBarTopBefore = tester.getTopLeft(appBarFinder).dy;
    final searchTopBefore = tester.getTopLeft(searchFinder).dy;
    final categoryTopBefore = tester.getTopLeft(categoryFinder).dy;

    if (Platform.isWindows) {
      final imageContext = tester.element(find.byType(AiNewsPage));
      await tester.runAsync(() async {
        for (final path in const [
          'assets/ai_news/digest_banner.png',
          'assets/ai_news/article_document.png',
          'assets/ai_news/article_city.png',
          'assets/ai_news/article_neural.png',
        ]) {
          await precacheImage(AssetImage(path), imageContext);
        }
      });
      await tester.pump();
      await expectLater(find.byType(AiNewsPage), matchesGoldenFile('goldens/ai_news_page_mobile.png'));
    }

    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(tester.getTopLeft(appBarFinder).dy, appBarTopBefore);
    expect(tester.getTopLeft(searchFinder).dy, lessThan(searchTopBefore));
    expect(tester.getTopLeft(categoryFinder).dy, lessThan(categoryTopBefore));
  });
}

/* 加载 Windows 中文字体,让移动端设计稿金图保留真实字形。 */
Future<void> _loadWindowsCjkFont() async {
  final cjkBytes = await File('C:/Windows/Fonts/simhei.ttf').readAsBytes();
  final iconBytes = await File('D:/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes();
  final cjkLoader = FontLoader('AiNewsGoldenFont')..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(cjkBytes))));
  final iconLoader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(iconBytes))));
  await Future.wait([cjkLoader.load(), iconLoader.load()]);
}
