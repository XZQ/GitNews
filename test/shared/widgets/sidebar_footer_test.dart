import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/sidebar/sidebar_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('anonymous sidebar profile does not claim name, PRO, or online', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(body: SidebarProfileCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('XZQ'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    expect(find.text('在线'), findsNothing);
    expect(find.text('匿名浏览'), findsOneWidget);
    expect(find.text('未登录'), findsOneWidget);
  });
}
