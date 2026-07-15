import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/monitor/widgets/monitor_settings_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('notification card renders only the supported in-app switch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MonitorNotificationCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('启用应用内告警中心'), findsOneWidget);
  });
}
