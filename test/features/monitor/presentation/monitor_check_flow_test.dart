import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_check_status.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:github_news/features/monitor/presentation/monitor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _digest = MonitorDigest(
  monitoredRepos: const [
    RepoEntity(
      fullName: 'organization/long-monitored-repository',
      description: '',
      language: 'Unknown',
      starCount: 0,
      starDelta: 9999,
      forkCount: 0,
      accentArgb: 0xff64748b,
      valueBasis: MetricBasis.unavailable,
      trendBasis: MetricBasis.unavailable,
    ),
  ],
  checks: {'organization/long-monitored-repository': RepoCheckStatus(attemptedAt: DateTime.utc(2026, 9, 12), failure: RepoCheckFailure.network)},
  alerts: const [],
  stats: const MonitorStats(monitoredCount: 1, monitoredDelta: 0, unreadAlertCount: 0, unreadAlertDelta: 0, triggeredTodayCount: 0, triggeredTodayDelta: 0, totalAlertCount: 0, totalAlertDelta: 0),
);

void main() {
  for (final brightness in Brightness.values) {
    for (final size in [const Size(390, 600), const Size(1200, 720)]) {
      testWidgets('monitor shows failures and unknown metrics in $brightness $size', (tester) async {
        await _pump(tester, brightness: brightness, size: size);
        expect(find.text('网络失败'), findsOneWidget);
        expect(find.text('正常'), findsNothing);
        expect(find.text('—'), findsWidgets);
        if (size.width < 600) {
          expect(find.byTooltip('重新检查全部仓库'), findsOneWidget);
          expect(find.byType(RefreshIndicator), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('empty search keeps the header so the query can be cleared', (tester) async {
    await _pump(tester, size: const Size(1200, 720));
    await tester.enterText(find.byType(TextField), 'no matches');
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('organization/long-monitored-repository'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('organization/long-monitored-repository'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/* 真实监控页面配合确定性仓库响应，保留搜索状态和布局逻辑。 */
Future<void> _pump(WidgetTester tester, {required Size size, Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        monitorRefreshInProgressProvider.overrideWithValue(false),
        filteredMonitorDigestProvider.overrideWith((ref) async => filterMonitorDigest(_digest, ref.watch(monitorSearchQueryProvider))),
      ],
      child: MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        theme: brightness == Brightness.light ? AppTheme.light(AppTheme.defaultSeed) : AppTheme.dark(AppTheme.defaultSeed),
        home: const MonitorPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
