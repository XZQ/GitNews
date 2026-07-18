import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/auth_models.dart';
import 'package:github_news/core/auth/auth_repository.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/profile/presentation/login_page.dart';
import 'package:github_news/features/profile/presentation/widgets/profile_user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/fake_auth_repository.dart';

void main() {
  testWidgets('unconfigured build keeps anonymous mode and does not offer PAT as app login', (tester) async {
    await _pump(tester, const LoginPage());

    expect(find.text('手机号登录'), findsOneWidget);
    expect(find.textContaining('当前构建未配置账号服务'), findsOneWidget);
    expect(find.text('继续匿名使用'), findsOneWidget);
    expect(find.text('配置 Personal Access Token'), findsNothing);
  });

  testWidgets('phone flow sends a normalized number and opens OTP verification', (tester) async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true, phone: true));
    addTearDown(repository.dispose);
    await _pump(tester, const LoginPage(), repository: repository);

    await tester.enterText(find.byType(TextField).first, '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.sentPhone, '+8613812345678');
    expect(find.text('输入验证码'), findsOneWidget);
    expect(find.textContaining('+86 138****5678'), findsOneWidget);
  });

  testWidgets('profile card uses app account identity and keeps GitHub connection separate', (tester) async {
    final repository = FakeAuthRepository(
      capabilities: const AuthCapabilities(isConfigured: true, phone: true),
      identity: const AppIdentity(userId: 'user-1', displayName: 'XZQ', phone: '+8613812345678', providers: {'phone'}),
    );
    addTearDown(repository.dispose);
    await _pump(tester, const Scaffold(body: ProfileUserCard()), repository: repository);

    expect(find.text('XZQ'), findsOneWidget);
    expect(find.text('账号'), findsOneWidget);
    expect(find.textContaining('手机号已验证'), findsOneWidget);
    expect(find.text('GitHub API 未连接'), findsOneWidget);

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 1);
  });
}

Future<void> _pump(WidgetTester tester, Widget child, {FakeAuthRepository? repository}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences), if (repository != null) authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
