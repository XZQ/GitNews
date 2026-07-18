import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:github_news/features/monitor/presentation/monitor_detail_page.dart';
import 'package:github_news/features/monitor/widgets/monitor_status_row.dart';

void main() {
  const repo = RepoEntity(
    fullName: 'very-long-organization/very-long-repository-name',
    description: 'A long repository description that should stay compact on a phone while remaining available in the desktop layout.',
    language: 'Dart',
    starCount: 527000,
    starDelta: 4400,
    forkCount: 49900,
    accentArgb: 0xFF0D9488,
    valueBasis: MetricBasis.observed,
    trendBasis: MetricBasis.observed,
    trend: [520000, 521000, 522500, 524000, 526000, 527000],
  );

  const stats = MonitorStats(
    monitoredCount: 7,
    monitoredDelta: 0,
    unreadAlertCount: 0,
    unreadAlertDelta: 0,
    triggeredTodayCount: 0,
    triggeredTodayDelta: 0,
    totalAlertCount: 0,
    totalAlertDelta: 0,
  );

  testWidgets('监控摘要在手机两列、桌面四列', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _StatusTestApp(stats: stats));
    await tester.pumpAndSettle();
    final compactFirst = tester.getTopLeft(find.text('监控仓库'));
    final compactThird = tester.getTopLeft(find.text('今日触发'));
    expect(compactThird.dy, greaterThan(compactFirst.dy));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const _StatusTestApp(stats: stats));
    await tester.pumpAndSettle();
    final desktopFirst = tester.getTopLeft(find.text('监控仓库'));
    final desktopThird = tester.getTopLeft(find.text('今日触发'));
    expect((desktopThird.dy - desktopFirst.dy).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('监控详情在手机显示真实趋势和明确空告警', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _MonitorTestApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Star 趋势'), findsOneWidget);
    expect(find.text('还没有该仓库的告警'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('监控详情在桌面使用趋势与告警双栏', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _MonitorTestApp(repo: repo));
    await tester.pumpAndSettle();

    final trendTitle = tester.getTopLeft(find.text('Star 趋势'));
    final alertTitle = tester.getTopLeft(find.text('告警历史'));
    expect((alertTitle.dy - trendTitle.dy).abs(), lessThan(40));
    expect(alertTitle.dx, greaterThan(trendTitle.dx));
    expect(tester.takeException(), isNull);
  });
}

class _StatusTestApp extends StatelessWidget {
  const _StatusTestApp({required this.stats});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MonitorStatusRow(stats: stats),
        ),
      ),
    );
  }
}

/*
*使用固定监控摘要启动监控详情页面。
*/
class _MonitorTestApp extends StatelessWidget {
  const _MonitorTestApp({required this.repo});

  // 当前测试使用的仓库。
  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final digest = MonitorDigest(
      monitoredRepos: [repo],
      alerts: const [],
      stats: const MonitorStats(
        monitoredCount: 1,
        monitoredDelta: 0,
        unreadAlertCount: 0,
        unreadAlertDelta: 0,
        triggeredTodayCount: 0,
        triggeredTodayDelta: 0,
        totalAlertCount: 0,
        totalAlertDelta: 0,
      ),
    );
    return ProviderScope(
      overrides: [
        visibleMonitorDigestProvider.overrideWith((ref) async => digest),
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
        home: MonitorDetailPage(repoFullName: repo.fullName),
      ),
    );
  }
}
