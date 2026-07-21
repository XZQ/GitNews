import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/widgets/monitor_page_header.dart';
import 'package:github_news/shared/widgets/data_provenance_badge.dart';
import 'package:github_news/shared/widgets/page_header.dart';

/* 验证仓库监控桌面页头只保留有操作价值的状态与动作。 */
void main() {
  testWidgets('仓库监控页头不显示实时数据胶囊', (tester) async {
    tester.view.physicalSize = const Size(1280, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const stats = MonitorStats(monitoredCount: 0, monitoredDelta: 0, unreadAlertCount: 0, unreadAlertDelta: 0, triggeredTodayCount: 0, triggeredTodayDelta: 0, totalAlertCount: 0, totalAlertDelta: 0);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [monitorFreshnessProvider.overrideWithValue(const AsyncData<DataFreshness>(DataFreshness.live))],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MonitorPageHeader(stats: stats)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataFreshnessBadge), findsNothing);
    expect(find.byType(HeaderStatPill), findsOneWidget);
    expect(find.text('0 未读'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
