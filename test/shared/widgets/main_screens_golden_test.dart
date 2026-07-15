import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_spacing.dart';
import 'package:github_news/shared/widgets/app_card.dart';
import 'package:github_news/shared/widgets/metric_card.dart';
import 'package:github_news/shared/widgets/page_header.dart';
import 'package:github_news/shared/widgets/section_header.dart';
import 'package:github_news/shared/widgets/skeleton.dart';

/*
*主屏视觉 golden 对照。
*- 5 个一级页的 [PageHeader] 单独锁定,覆盖标题/副标题/图标/搜索框/状态胶囊/动作按钮组合。
*- 额外的「主屏完整 chrome」组合锁定:PageHeader + SectionHeader + MetricCard 行 +
  AppCard 列表 + Skeleton 加载态,模拟桌面端 B/C 区域的真实视觉结构。
*修改 [PageHeader] / 共享卡片 / MetricCard / AppCard 时,
*跑 `flutter test --update-goldens` 重新生成基线。
*/
void main() {
  Future<void> pumpHeader(WidgetTester tester, Widget header) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(body: header),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  Future<void> pumpScreen(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(backgroundColor: const Color(0xFFF7F5F0), body: SizedBox(width: 1200, height: 800, child: SingleChildScrollView(child: body))),
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
        pills: const [HeaderStatPill(icon: Icons.circle, label: '12', color: Colors.green)],
        actions: [IconButton(tooltip: l10n.tr('common.refresh'), onPressed: () {}, icon: const Icon(Icons.add_circle_outline_rounded, size: 20))],
        onRefresh: () {});
  }

  group('Windows golden baselines', () {
    testWidgets('Main screen header — Home golden', (tester) async {
      await pumpHeader(
          tester,
          Builder(
              builder: (context) => headerConfig(
                    context,
                    'home.title',
                    'home.subtitle',
                    Icons.dashboard_outlined,
                  )));
      await expectLater(find.byType(PageHeader), matchesGoldenFile('goldens/main_header_home.png'));
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
                  )));
      await expectLater(find.byType(PageHeader), matchesGoldenFile('goldens/main_header_ai_news.png'));
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
                  )));
      await expectLater(find.byType(PageHeader), matchesGoldenFile('goldens/main_header_trending.png'));
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
                  )));
      await expectLater(find.byType(PageHeader), matchesGoldenFile('goldens/main_header_tech_hotspot.png'));
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
                  )));
      await expectLater(find.byType(PageHeader), matchesGoldenFile('goldens/main_header_monitor.png'));
    });
  }, skip: !Platform.isWindows);

  group('Windows golden baselines — full screen chrome', () {
    testWidgets('Main screen body — header + metrics + cards + skeleton', (tester) async {
      await pumpScreen(tester, Builder(builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                icon: Icons.dashboard_outlined,
                title: l10n.tr('home.title'),
                subtitle: l10n.tr('home.subtitle'),
                searchHint: l10n.tr('common.search'),
                pills: const [HeaderStatPill(icon: Icons.circle, label: '12', color: Colors.green)],
                actions: [IconButton(tooltip: l10n.tr('common.refresh'), onPressed: () {}, icon: const Icon(Icons.refresh_rounded, size: 20))],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: l10n.tr('trending.page.repos'), subtitle: l10n.tr('trending.list.subtitle.short')),
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      children: [
                        Expanded(child: MetricCard(icon: Icons.star_rounded, title: 'Star 增长', value: '1.2k')),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: MetricCard(icon: Icons.fork_right, title: 'Fork', value: '180'))
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppCard(child: Column(children: [Skeleton(height: 72), SizedBox(height: AppSpacing.md), Skeleton(height: 72)]))
            ],
          ),
        );
      }));
      await expectLater(find.byType(SingleChildScrollView), matchesGoldenFile('goldens/main_screen_full_chrome.png'));
    });
  }, skip: !Platform.isWindows);
}
