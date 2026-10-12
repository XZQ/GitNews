import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/github_token_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/controlled_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('GitHubTokenController', () {
    test('should default to empty token', () async {
      final container = await _container();
      container.read(githubTokenControllerProvider);
      await _drainAsyncInit();

      final state = container.read(githubTokenControllerProvider);

      expect(state.hasToken, isFalse);
      expect(state.maskedToken, '未配置');
      expect(state.cacheScope, 'anonymous');
    });

    test('should migrate token from legacy preferences', () async {
      final container = await _container({'github_personal_access_token': 'github_pat_1234567890'});
      container.read(githubTokenControllerProvider);
      await _drainAsyncInit();

      final state = container.read(githubTokenControllerProvider);
      final prefs = container.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();

      expect(state.hasToken, isTrue);
      expect(state.maskedToken, 'gith...7890');
      expect(state.cacheScope, isNot('anonymous'));
      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(await secure.read(key: 'github_personal_access_token'), 'github_pat_1234567890');
    });

    test('should persist and clear token', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const secure = FlutterSecureStorage();
      final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);

      await container.read(githubTokenControllerProvider.notifier).setToken('  ghp_abcdef  ');

      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(await secure.read(key: 'github_personal_access_token'), 'ghp_abcdef');
      expect(container.read(githubTokenControllerProvider).hasToken, isTrue);

      await container.read(githubTokenControllerProvider.notifier).clear();

      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(await secure.read(key: 'github_personal_access_token'), isNull);
      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
    });

    test('secure token wins over legacy plaintext and clearing does not resurrect either token', () async {
      final secure = ControlledSecureStorage({'github_personal_access_token': 'secure-token'});
      final container = await _controlledContainer(secure, initial: {'github_personal_access_token': 'legacy-token'});
      final controller = container.read(githubTokenControllerProvider.notifier);
      await controller.ready;
      final prefs = container.read(sharedPreferencesProvider);

      expect(container.read(githubTokenControllerProvider).token, 'secure-token');
      expect(prefs.containsKey('github_personal_access_token'), isFalse);
      await controller.clear();
      container.invalidate(githubTokenControllerProvider);
      await container.read(githubTokenControllerProvider.notifier).ready;

      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
      expect(secure.values, isEmpty);
      expect(prefs.containsKey('github_personal_access_token'), isFalse);
    });

    test('delayed startup read cannot overwrite a newly saved token', () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final secure = ControlledSecureStorage({'github_personal_access_token': 'old-token'})
        ..nextReadGate = gate
        ..nextReadStarted = started;
      final container = await _controlledContainer(secure);
      final controller = container.read(githubTokenControllerProvider.notifier);
      await started.future;
      final saving = controller.setToken('new-token');
      gate.complete();
      await saving;

      expect(container.read(githubTokenControllerProvider).token, 'new-token');
      expect(secure.values['github_personal_access_token'], 'new-token');
    });

    test('clear waits for delayed legacy migration and stays cleared after restart', () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final secure = ControlledSecureStorage()
        ..nextReadGate = gate
        ..nextReadStarted = started;
      final container = await _controlledContainer(secure, initial: {'github_personal_access_token': 'legacy-token'});
      final controller = container.read(githubTokenControllerProvider.notifier);
      await started.future;
      final clearing = controller.clear();
      gate.complete();
      await clearing;
      container.invalidate(githubTokenControllerProvider);
      await container.read(githubTokenControllerProvider.notifier).ready;

      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
      expect(secure.values, isEmpty);
      expect(container.read(sharedPreferencesProvider).containsKey('github_personal_access_token'), isFalse);
    });

    test('token is published only after persistence and failed writes preserve the previous token', () async {
      final secure = ControlledSecureStorage({'github_personal_access_token': 'old-token'});
      final container = await _controlledContainer(secure);
      final controller = container.read(githubTokenControllerProvider.notifier);
      await controller.ready;
      final gate = Completer<void>();
      final started = Completer<void>();
      secure
        ..nextWriteGate = gate
        ..nextWriteStarted = started;
      final saving = controller.setToken('new-token');
      await started.future;
      expect(container.read(githubTokenControllerProvider).token, 'old-token');
      gate.complete();
      await saving;
      secure.failWrite = true;
      await expectLater(controller.setToken('failed-token'), throwsStateError);
      expect(container.read(githubTokenControllerProvider).token, 'new-token');
      expect(secure.values['github_personal_access_token'], 'new-token');
      secure.failWrite = false;
      await controller.setToken('recovered-token');
      expect(container.read(githubTokenControllerProvider).token, 'recovered-token');
    });

    test('failed secure deletion keeps the saved token visible for retry', () async {
      final secure = ControlledSecureStorage({'github_personal_access_token': 'saved-token'});
      final container = await _controlledContainer(secure);
      final controller = container.read(githubTokenControllerProvider.notifier);
      await controller.ready;
      secure.failDelete = true;

      await expectLater(controller.clear(), throwsStateError);

      expect(container.read(githubTokenControllerProvider).token, 'saved-token');
      secure.failDelete = false;
      await controller.clear();
      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
    });

    test('legacy cleanup failure cannot replace the durable token and later saving can recover', () async {
      final secure = ControlledSecureStorage({'github_personal_access_token': 'old-token'});
      final preferences = _FailingRemovePreferences({'github_personal_access_token': 'legacy-token'})..failRemove = true;
      final container = await _controlledContainer(secure, preferences: preferences);
      final controller = container.read(githubTokenControllerProvider.notifier);
      await controller.ready;

      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
      await expectLater(controller.setToken('new-token'), throwsStateError);
      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
      expect(secure.values['github_personal_access_token'], 'old-token');
      expect(preferences.values['github_personal_access_token'], 'legacy-token');

      preferences.failRemove = false;
      container.invalidate(githubTokenControllerProvider);
      await container.read(githubTokenControllerProvider.notifier).ready;
      expect(container.read(githubTokenControllerProvider).token, 'old-token');
      await container.read(githubTokenControllerProvider.notifier).setToken('recovered-token');
      expect(container.read(githubTokenControllerProvider).token, 'recovered-token');
      expect(secure.values['github_personal_access_token'], 'recovered-token');
      expect(preferences.values, isEmpty);
    });
  });
}

Future<ProviderContainer> _container([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)]);
  addTearDown(container.dispose);
  return container;
}

Future<void> _drainAsyncInit() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/* 创建可精确控制异步安全存储的 Token 测试容器。 */
Future<ProviderContainer> _controlledContainer(ControlledSecureStorage secure, {Map<String, Object> initial = const {}, SharedPreferences? preferences}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), secureStorageProvider.overrideWithValue(secure)]);
  addTearDown(container.dispose);
  return container;
}

/*
*模拟旧明文删除返回失败，用于验证跨存储写入顺序。
*/
class _FailingRemovePreferences extends Mock implements SharedPreferences {
  _FailingRemovePreferences(this.values) {
    when(() => getString(any())).thenAnswer((invocation) => values[invocation.positionalArguments.first]);
    when(() => containsKey(any())).thenAnswer((invocation) => values.containsKey(invocation.positionalArguments.first));
    when(() => remove(any())).thenAnswer((invocation) async {
      if (failRemove) {
        return false;
      }
      values.remove(invocation.positionalArguments.first);
      return true;
    });
  }

  // 只保存测试使用的旧偏好内容。
  final Map<String, String> values;

  // 让 remove 保留原值并返回失败。
  bool failRemove = false;
}
