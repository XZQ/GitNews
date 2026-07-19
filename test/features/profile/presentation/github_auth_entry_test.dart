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

    expect(find.text('登录方式'), findsOneWidget);
    expect(find.textContaining('登录服务暂时不可用'), findsOneWidget);
    expect(find.textContaining('手机号'), findsNothing);
    expect(find.text('继续匿名使用'), findsOneWidget);
    expect(find.text('配置 Personal Access Token'), findsNothing);
  });

  testWidgets('configured login offers email Google and GitHub, then opens email verification', (tester) async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true));
    addTearDown(repository.dispose);
    await _pump(tester, const LoginPage(), repository: repository);

    expect(find.text('使用 Google 登录'), findsOneWidget);
    expect(find.text('使用 GitHub 登录'), findsOneWidget);
    expect(find.textContaining('手机号'), findsNothing);

    await tester.tap(find.text('使用 Google 登录'));
    await tester.pump();
    expect(repository.openedProvider, AppAuthProvider.google);

    await tester.tap(find.text('使用 GitHub 登录'));
    await tester.pump();
    expect(repository.openedProvider, AppAuthProvider.github);

    await tester.enterText(find.byType(TextField).first, 'developer@example.com');
    await tester.tap(find.text('发送邮箱验证码'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.sentEmail, 'developer@example.com');
    expect(find.text('输入验证码'), findsOneWidget);
    expect(find.textContaining('de***@example.com'), findsOneWidget);
  });

  testWidgets('profile card uses app account identity and keeps GitHub connection separate', (tester) async {
    final repository = FakeAuthRepository(
      capabilities: const AuthCapabilities(isConfigured: true),
      identity: const AppIdentity(userId: 'user-1', displayName: 'XZQ', email: 'developer@example.com', providers: {'email'}),
    );
    addTearDown(repository.dispose);
    await _pump(tester, const Scaffold(body: ProfileUserCard()), repository: repository);

    expect(find.text('XZQ'), findsOneWidget);
    expect(find.text('账号'), findsOneWidget);
    expect(find.textContaining('邮箱已验证'), findsOneWidget);
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
