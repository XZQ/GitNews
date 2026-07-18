import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_hot_daily.dart';
import 'package:github_news/features/ai_news/domain/ai_hot_status.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_hot_daily_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('官方日报卡展示来源、版本并打开指定日期详情', (tester) async {
    final report = AiHotDailyReport(
      date: '2026-07-19',
      generatedAt: DateTime.utc(2026, 7, 19, 1),
      windowStart: DateTime.utc(2026, 7, 18),
      windowEnd: DateTime.utc(2026, 7, 19),
      lead: const AiHotDailyLead(
        title: 'AI 模型与智能体进入新阶段',
        paragraph: '本期聚焦模型发布、智能体工具与行业应用。',
      ),
      sections: const [
        AiHotDailySection(
          label: '模型',
          items: [
            AiHotDailyItem(
              title: '新模型发布',
              summary: '模型能力获得更新。',
              sourceUrl: 'https://example.com/original',
              sourceName: 'Example',
            ),
          ],
        ),
      ],
      flashes: const [
        AiHotDailyFlash(
          title: '行业快讯',
          sourceName: 'Example',
          sourceUrl: 'https://example.com/flash',
          publishedAt: null,
        ),
      ],
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: AiHotDailyCard())),
        GoRoute(
          path: '/ai_news/daily/:date',
          builder: (_, state) => Scaffold(body: Text('日报详情 ${state.pathParameters['date']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiHotLatestDailyProvider.overrideWith(
            (ref) async => DataResult(data: report, freshness: DataFreshness.live),
          ),
          aiHotVersionProvider.overrideWith(
            (ref) async => const DataResult(
              data: AiHotVersion(
                apiVersion: '1.4.0',
                skillVersion: '0.3.6',
                updatedAt: '2026-07-18',
                changelogUrl: 'https://aihot.virxact.com/changelog',
                recentChanges: [],
              ),
              freshness: DataFreshness.live,
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI HOT 官方日报'), findsOneWidget);
    expect(find.text('每日精编 · 无需 API Key'), findsOneWidget);
    expect(find.text('AI 模型与智能体进入新阶段'), findsOneWidget);
    expect(find.text('2 条精选'), findsOneWidget);
    expect(find.text('2026-07-19 · API v1.4.0'), findsOneWidget);
    expect(find.text('内容由 AI HOT 精编'), findsOneWidget);

    await tester.tap(find.text('查看完整日报'));
    await tester.pumpAndSettle();

    expect(find.text('日报详情 2026-07-19'), findsOneWidget);
  });
}
