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

  test('仅使用内置 Agnes 并清理旧版可编辑配置', () async {
    FlutterSecureStorage.setMockInitialValues({'ai_digest_api_key': 'legacy-test-key'});
    final container = await _container({'ai_digest_base_url': 'https://legacy.example.com/v1', 'ai_digest_model': 'legacy-model'});
    container.read(aiDigestConfigControllerProvider);
    await _drainAsyncInit();

    final state = container.read(aiDigestConfigControllerProvider);
    expect(ApiEndpointsConfig.aiDigestDefaultBaseUrl, 'https://apihub.agnes-ai.com/v1');
    expect(ApiEndpointsConfig.aiDigestDefaultModel, 'agnes-2.0-flash');
    expect(state.apiKey, ApiEndpointsConfig.aiDigestDefaultApiKey.isEmpty ? isNull : ApiEndpointsConfig.aiDigestDefaultApiKey);
    expect(await const FlutterSecureStorage().read(key: 'ai_digest_api_key'), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('ai_digest_base_url'), isNull);
    expect(preferences.getString('ai_digest_model'), isNull);
  });

  test('构建参数中的默认 Key 会写入系统安全存储', () async {
    final container = await _container();
    container.read(aiDigestConfigControllerProvider);
    await _drainAsyncInit();

    final configuredKey = ApiEndpointsConfig.aiDigestDefaultApiKey;
    expect(container.read(aiDigestConfigControllerProvider).apiKey, configuredKey);
    expect(await const FlutterSecureStorage().read(key: 'ai_enrichment_agnes_api_key'), configuredKey);
  }, skip: ApiEndpointsConfig.aiDigestDefaultApiKey.isEmpty ? '需要 AI_ENRICHMENT_AGNES_API_KEY 构建参数' : false);
}

Future<ProviderContainer> _container([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
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
