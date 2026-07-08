import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/page_header.dart';

/* 
*5 个主屏顶部条(PageHeader)的 golden 渲染对照。
*覆盖标题/副标题/图标/搜索框/状态胶囊/刷新与动作按钮等主 chrome 组合,
*作为视觉回归基线。修改 [PageHeader] 或主屏头部视觉时,
*跑 `flutter test --update-goldens` 重新生成基线。
*/
void main() {
  Future<void> pumpHeader(
    WidgetTester tester,
    Widget header,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(body: header),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  Widget headerConfig(
    BuildContext context,
    String titleKey,
    String subtitleKey,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      icon: icon,
      title: l10n.tr(titleKey),
      subtitle: l10n.tr(subtitleKey),
      searchHint: l10n.tr('common.search'),
      searchValue: '',
      onSearchChanged: (_) {},
      onSearchSubmitted: (_) {},
      pills: const [
        HeaderStatPill(
          icon: Icons.circle,
          label: '12',
          color: Colors.green,
        ),
      ],
      actions: [
        IconButton(
          tooltip: l10n.tr('common.refresh'),
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        ),
      ],
      onRefresh: () {},
    );
  }

  testWidgets('Main screen header — Home golden', (tester) async {
    await pumpHeader(
      tester,
      Builder(
        builder: (context) =>
            headerConfig(context, 'home.title', 'home.subtitle', Icons.dashboard_outlined),
      ),
    );
    await expectLater(
      find.byType(PageHeader),
      matchesGoldenFile('goldens/main_header_home.png'),
    );
  });

  testWidgets('Main screen header — AI News golden', (tester) async {
    await pumpHeader(
      tester,
      Builder(
        builder: (context) => headerConfig(
          context,
          'ai_news.title',
          'ai_news.subtitle',
          Icons.auto_awesome_rounded,
        ),
      ),
    );
    await expectLater(
      find.byType(PageHeader),
      matchesGoldenFile('goldens/main_header_ai_news.png'),
    );
  });

  testWidgets('Main screen header — Trending golden', (tester) async {
    await pumpHeader(
      tester,
      Builder(
        builder: (context) => headerConfig(
          context,
          'trending.title',
          'trending.page_header.subtitle',
          Icons.trending_up_rounded,
        ),
      ),
    );
    await expectLater(
      find.byType(PageHeader),
      matchesGoldenFile('goldens/main_header_trending.png'),
    );
  });

  testWidgets('Main screen header — Tech Hotspot golden', (tester) async {
    await pumpHeader(
      tester,
      Builder(
        builder: (context) => headerConfig(
          context,
          'tech_hotspot.title',
          'tech_hotspot.subtitle',
          Icons.device_hub_rounded,
        ),
      ),
    );
    await expectLater(
      find.byType(PageHeader),
      matchesGoldenFile('goldens/main_header_tech_hotspot.png'),
    );
  });

  testWidgets('Main screen header — Monitor golden', (tester) async {
    await pumpHeader(
      tester,
      Builder(
        builder: (context) => headerConfig(
          context,
          'monitor.title',
          'monitor.subtitle',
          Icons.radar_rounded,
        ),
      ),
    );
    await expectLater(
      find.byType(PageHeader),
      matchesGoldenFile('goldens/main_header_monitor.png'),
    );
  });
}
