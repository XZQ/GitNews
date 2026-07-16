import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('默认使用 LongCat 且保存后的 Key 只显示 xxxxxxxx', () async {
    final container = await _container();
    container.read(aiDigestConfigControllerProvider);
    await _drainAsyncInit();

    expect(container.read(aiDigestConfigControllerProvider).baseUrl, 'https://api.longcat.chat/openai');
    expect(container.read(aiDigestConfigControllerProvider).model, 'LongCat-2.0');

    await container.read(aiDigestConfigControllerProvider.notifier).save(
          apiKey: 'sk-private-value',
          baseUrl: 'https://api.deepseek.com/',
          model: 'deepseek-v4-flash',
        );

    final state = container.read(aiDigestConfigControllerProvider);
    expect(state.configured, isTrue);
    expect(state.maskedKey, 'xxxxxxxx');
    expect(state.baseUrl, 'https://api.deepseek.com');
    expect(await const FlutterSecureStorage().read(key: 'ai_digest_api_key'), 'sk-private-value');
  });

  test(
    '构建参数中的默认 Key 会写入系统安全存储',
    () async {
      final container = await _container();
      container.read(aiDigestConfigControllerProvider);
      await _drainAsyncInit();

      final configuredKey = ApiEndpointsConfig.aiDigestDefaultApiKey;
      expect(container.read(aiDigestConfigControllerProvider).apiKey, configuredKey);
      expect(container.read(aiDigestConfigControllerProvider).maskedKey, 'xxxxxxxx');
      expect(await const FlutterSecureStorage().read(key: 'ai_digest_api_key'), configuredKey);
    },
    skip: ApiEndpointsConfig.aiDigestDefaultApiKey.isEmpty ? '需要 AI_DIGEST_DEFAULT_API_KEY 构建参数' : false,
  );
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

Future<void> _drainAsyncInit() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
