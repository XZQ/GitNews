import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/project/application/project_providers.dart';
import 'package:github_news/features/project/presentation/widgets/project_page_header.dart';
import 'package:github_news/shared/widgets/data_provenance_badge.dart';

/* 验证深度报告桌面页头不展示冗余的数据来源标签。 */
void main() {
  testWidgets('深度报告页头不显示种子数据胶囊', (tester) async {
    tester.view.physicalSize = const Size(1280, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectFreshnessProvider.overrideWithValue(const AsyncData<DataFreshness>(DataFreshness.seed))],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProjectPageHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataFreshnessBadge), findsNothing);
    expect(find.text('种子'), findsNothing);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
