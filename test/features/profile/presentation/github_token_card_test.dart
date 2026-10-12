import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/github_token_controller.dart';
import 'package:github_news/features/profile/presentation/widgets/github_token_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/controlled_secure_storage.dart';

const _tokenKey = 'github_personal_access_token';

void main() {
  testWidgets('saving failure keeps the current token and input while displaying a retry message', (tester) async {
    final secure = ControlledSecureStorage({_tokenKey: 'old-token'});
    final container = await _pump(tester, secure);
    secure.failWrite = true;
    await tester.enterText(find.byType(TextField), 'new-token');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('GitHub Token saved'), findsNothing);
    expect(container.read(githubTokenControllerProvider).token, 'old-token');
    expect(secure.values[_tokenKey], 'old-token');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'new-token');
    expect(tester.takeException(), isNull);

    secure.failWrite = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(githubTokenControllerProvider).token, 'new-token');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing failure keeps the saved token visible and reports the error', (tester) async {
    final secure = ControlledSecureStorage({_tokenKey: 'saved-token'});
    final container = await _pump(tester, secure);
    secure.failDelete = true;
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('GitHub Token cleared'), findsNothing);
    expect(container.read(githubTokenControllerProvider).token, 'saved-token');
    expect(secure.values[_tokenKey], 'saved-token');
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving can complete after the token card is removed without touching its disposed input', (tester) async {
    final secure = ControlledSecureStorage({_tokenKey: 'old-token'});
    final container = await _pump(tester, secure);
    final gate = Completer<void>();
    final started = Completer<void>();
    secure
      ..nextWriteGate = gate
      ..nextWriteStarted = started;
    await tester.enterText(find.byType(TextField), 'new-token');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await started.future;
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await container.read(githubTokenControllerProvider.notifier).ready;
    await tester.pump();

    expect(secure.values[_tokenKey], 'new-token');
    expect(tester.takeException(), isNull);
  });
}

/* 挂载真实 Token 控制器与卡片，存储故障通过可控替身触发。 */
Future<ProviderContainer> _pump(WidgetTester tester, ControlledSecureStorage secure) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1024, 768);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), secureStorageProvider.overrideWithValue(secure)]);
  addTearDown(container.dispose);
  await container.read(githubTokenControllerProvider.notifier).ready;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en', 'US'),
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: GitHubTokenCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
