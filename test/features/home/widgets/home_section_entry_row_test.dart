import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/provider_retry_policy.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/home/widgets/devintel/home_section_entry_row.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:github_news/features/project/application/project_providers.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:go_router/go_router.dart';

/*
*隔离资讯加载，避免测试访问存储或网络。
*/
class _News extends AiNewsItemsNotifier {
  _News(this.result);

  // 受测试控制的加载结果。
  final Future<List<AiNewsItem>> result;

  @override
  /* 返回本项测试的样本。 */
  Future<List<AiNewsItem>> build() => result;
}

void main() {
  testWidgets('counts loaded samples and explains dated negative Star change without summing scores', (tester) async {
    await tester.pumpWidget(_app(tester));
    await tester.pumpAndSettle();
    expect(find.text('2 条已加载'), findsOneWidget);
    expect(find.text('已加载内容来自 2 个来源'), findsOneWidget);
    expect(find.text('2 个样本仓库'), findsOneWidget, reason: 'Duplicate repo names are counted once');
    expect(find.text('Star 净变化 -10 · 样本 1/2\n2026-09-01 至 2026-09-12 (UTC)'), findsOneWidget);
    expect(find.text('当前雷达样本'), findsOneWidget);
    expect(find.textContaining('条新更'), findsNothing);
    expect(find.textContaining('+-'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('+180'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending and failed counts stay unknown, successful empty data is zero', (tester) async {
    final news = Completer<List<AiNewsItem>>();
    await tester.pumpWidget(_app(tester, news: news.future));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('加载中'), findsOneWidget);
    expect(find.text('0 条已加载'), findsNothing);
    news.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('加载失败，可进入栏目重试'), findsOneWidget);
    expect(find.text('0 个样本项目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing dated observations do not fabricate Star change', (tester) async {
    await tester.pumpWidget(_app(tester, repos: [_repo('sample/new')]));
    await tester.pumpAndSettle();
    expect(find.text('当前样本 · Star 历史待积累'), findsOneWidget);
    expect(find.textContaining('Star 净变化'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    for (final width in [360.0, 760.0, 1280.0]) {
      for (final language in ['zh', 'en']) {
        testWidgets('entry navigation survives $brightness width=$width $language text scale 2', (tester) async {
          tester.view.physicalSize = Size(width, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(_app(tester, brightness: brightness, language: language, scale: 2));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final router = GoRouter.of(tester.element(find.byType(HomeSectionEntryRow)));
          for (final path in ['/ai_news', '/trending', '/tech_hotspot', '/monitor', '/project']) {
            await tester.ensureVisible(find.byKey(ValueKey(path)));
            await tester.tap(find.byKey(ValueKey(path)));
            await tester.pumpAndSettle();
            expect(find.text('opened:$path'), findsOneWidget);
            router.go('/home');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
}

/* 构建具备五个真实跳转目标的本地组件测试。 */
Widget _app(WidgetTester tester, {Future<List<AiNewsItem>>? news, List<RepoEntity>? repos, Brightness brightness = Brightness.light, String language = 'zh', double scale = 1}) {
  final observed = _repo('sample/observed').copyWith(trendBasis: MetricBasis.observed, trend: [100, 90], trendDates: [DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 12)]);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: SingleChildScrollView(child: HomeSectionEntryRow())),
      ),
      for (final path in ['/ai_news', '/trending', '/tech_hotspot', '/monitor', '/project'])
        GoRoute(
          path: path,
          builder: (_, __) => Scaffold(body: Text('opened:$path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      aiNewsItemsNotifierProvider.overrideWith(() => _News(news ?? Future.value([_article('first'), _article('second')]))),
      trendingClockProvider.overrideWithValue(() => DateTime.utc(2026, 9, 12)),
      trendingDigestProvider.overrideWith(
        (ref) async => TrendingDigest(
          trendingRepos: repos ?? [observed, _repo('sample/new')],
          recentRepos: repos == null ? [observed] : [],
          languages: const [],
          primaryTrend: const [],
          secondaryTrend: const [],
          tertiaryTrend: const [],
        ),
      ),
      techHotspotDigestProvider.overrideWith(
        (ref) async => TechHotspotDigest(
          languages: const [],
          topics: [for (var i = 0; i < 2; i++) TechTopic(id: '$i', name: 'topic', category: 'AI', heat: 80, growth: 50, mentions: 10, relatedRepos: 5, summary: '')],
          heatTrend: const [],
          hotTags: const [],
        ),
      ),
      visibleMonitorDigestProvider.overrideWith(
        (ref) async => const MonitorDigest(
          monitoredRepos: [],
          alerts: [],
          stats: MonitorStats(monitoredCount: 0, monitoredDelta: 0, unreadAlertCount: 0, unreadAlertDelta: 0, triggeredTodayCount: 0, triggeredTodayDelta: 0, totalAlertCount: 0, totalAlertDelta: 0),
        ),
      ),
      projectDigestProvider.overrideWith((ref) async => const ProjectDigest(repos: [], contributors: [], primaryTrend: [], secondaryTrend: [], activities: [])),
    ],
    child: MaterialApp.router(
      locale: Locale(language),
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.fromSeed(brightness, AppColors.brand),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      routerConfig: router,
    ),
  );
}

/* 构建高分资讯样本，验证分数不会被当成增量相加。 */
AiNewsItem _article(String id) =>
    AiNewsItem(id: id, category: AiNewsCategory.industry, title: id, titleEn: '', summary: '', source: id, url: '', permalink: '', publishedAt: DateTime.utc(2026, 9, 12), score: 90, selected: true);

/* 未携带历史的仓库不能提供净增量。 */
RepoEntity _repo(String name) => RepoEntity(fullName: name, description: '', language: 'Dart', starCount: 100, starDelta: 999, forkCount: 0, accentArgb: 0);
