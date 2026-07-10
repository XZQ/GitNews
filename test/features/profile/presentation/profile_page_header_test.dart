import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/profile/presentation/widgets/profile_page_header.dart';

void main() {
  testWidgets('profile header does not advertise an unavailable PRO tier', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh', 'CN'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ProfilePageHeader()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRO'), findsNothing);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
  });
}
