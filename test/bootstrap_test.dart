import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/bootstrap.dart';
import 'package:github_news/core/auth/auth_models.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('initializer converts dependency failures into a recovery result', () async {
    final result = await initializeApplication(sharedPreferencesLoader: () async => throw StateError('prefs failed'), databaseOpener: LocalDatabase.openInMemory);

    expect(result.isSuccess, isFalse);
    expect(result.error, isA<StateError>());
  });

  test('auth initialization failure does not block local-first bootstrap', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await initializeApplication(
      sharedPreferencesLoader: SharedPreferences.getInstance,
      databaseOpener: LocalDatabase.openInMemory,
      authRepositoryLoader: (_) async => throw StateError('auth unavailable'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.authRepository.capabilities.isConfigured, isTrue);
    await expectLater(result.authRepository.sendEmailOtp('developer@example.com'), throwsA(isA<AppAuthFailure>()));
    await result.database?.close();
  });

  testWidgets('bootstrap failure retries without automatically opening data', (tester) async {
    var attempts = 0;
    var openDataCalls = 0;

    await tester.pumpWidget(
      BootstrapApp(
        initializer: () async {
          attempts++;
          return BootstrapResult.failure(StateError('database locked'), StackTrace.empty);
        },
        openDataDirectory: () async {
          openDataCalls++;
          return true;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    expect(openDataCalls, 0);

    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(attempts, 2);
    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    expect(openDataCalls, 0);
  });
}
