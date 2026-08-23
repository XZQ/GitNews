import 'dart:async';

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

  test('independent initializers run in parallel instead of sequentially', () async {
    SharedPreferences.setMockInitialValues({});
    // prefs 刻意等待数据库打开才完成;串行实现会在这里超时失败。
    final databaseOpened = Completer<void>();
    final result = await initializeApplication(
      sharedPreferencesLoader: () async {
        await databaseOpened.future.timeout(const Duration(seconds: 2));
        return SharedPreferences.getInstance();
      },
      databaseOpener: () async {
        final database = await LocalDatabase.openInMemory();
        databaseOpened.complete();
        return database;
      },
    );

    expect(result.isSuccess, isTrue);
    await result.database?.close();
  });

  test('slow database open is drained before failure returns (no sqlite handle leak)', () async {
    SharedPreferences.setMockInitialValues({});
    // prefs 立即失败,数据库迟迟才打开:失败路径必须等数据库落定并关闭,
    // 否则并行打开的 sqlite 连接会在返回后无人释放。
    final release = Completer<void>();
    var settled = false;
    final resultFuture =
        initializeApplication(
          sharedPreferencesLoader: () async => throw StateError('prefs failed'),
          databaseOpener: () async {
            await release.future;
            return LocalDatabase.openInMemory();
          },
        ).then((result) {
          settled = true;
          return result;
        });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(settled, isFalse, reason: '失败路径应等待 pending 的数据库打开完成后再返回');

    release.complete();
    final result = await resultFuture.timeout(const Duration(seconds: 5));
    expect(result.isSuccess, isFalse);
    expect(result.error, isA<StateError>());
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
