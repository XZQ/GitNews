import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/profile/presentation/login_page.dart';
import 'package:github_news/features/profile/presentation/widgets/profile_user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('unconfigured build offers PAT instead of broken OAuth login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('配置 Personal Access Token'), findsOneWidget);
    expect(find.text('使用 GitHub 登录'), findsNothing);
    expect(find.textContaining('跨设备'), findsNothing);
  });

  testWidgets('profile user card routes anonymous users toward PAT setup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProfileUserCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('配置 Personal Access Token'), findsOneWidget);
    expect(find.text('登录'), findsNothing);
  });
}
