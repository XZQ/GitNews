import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/github_token_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final container = await _container({
        'github_personal_access_token': 'github_pat_1234567890',
      });
      container.read(githubTokenControllerProvider);
      await _drainAsyncInit();

      final state = container.read(githubTokenControllerProvider);
      final prefs = container.read(sharedPreferencesProvider);
      const secure = FlutterSecureStorage();

      expect(state.hasToken, isTrue);
      expect(state.maskedToken, 'gith...7890');
      expect(state.cacheScope, isNot('anonymous'));
      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(
        await secure.read(key: 'github_personal_access_token'),
        'github_pat_1234567890',
      );
    });

    test('should persist and clear token', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const secure = FlutterSecureStorage();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(githubTokenControllerProvider.notifier)
          .setToken('  ghp_abcdef  ');

      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(
        await secure.read(key: 'github_personal_access_token'),
        'ghp_abcdef',
      );
      expect(container.read(githubTokenControllerProvider).hasToken, isTrue);

      await container.read(githubTokenControllerProvider.notifier).clear();

      expect(prefs.getString('github_personal_access_token'), isNull);
      expect(await secure.read(key: 'github_personal_access_token'), isNull);
      expect(container.read(githubTokenControllerProvider).hasToken, isFalse);
    });
  });
}

Future<ProviderContainer> _container([
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _drainAsyncInit() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
