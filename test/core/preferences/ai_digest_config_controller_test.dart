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

  test('清理旧版共享密钥且不再加载为客户端状态', () async {
    FlutterSecureStorage.setMockInitialValues({'ai_digest_api_key': 'legacy-test-key', 'ai_enrichment_agnes_api_key': 'legacy-publisher-test-key'});
    final container = await _container({'ai_digest_base_url': 'https://legacy.example.com/v1', 'ai_digest_model': 'legacy-model'});
    container.read(aiDigestConfigControllerProvider);
    await _drainAsyncInit();

    final state = container.read(aiDigestConfigControllerProvider);
    expect(ApiEndpointsConfig.aiDigestDefaultModel, 'agnes-2.0-flash');
    expect(state.serviceUrl, ApiEndpointsConfig.aiEnrichmentProxyBaseUrl);
    expect(state.configured, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'ai_digest_api_key'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'ai_enrichment_agnes_api_key'), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('ai_digest_base_url'), isNull);
    expect(preferences.getString('ai_digest_model'), isNull);
  });

  test('生成需要安全服务地址和应用账号会话', () {
    expect(const AiDigestConfigState(serviceUrl: 'https://proxy.example').configured, isFalse);
    expect(const AiDigestConfigState(serviceUrl: 'https://proxy.example', isAuthenticated: true).configured, isTrue);
    expect(const AiDigestConfigState(serviceUrl: 'http://remote.example', isAuthenticated: true).configured, isFalse);
    expect(const AiDigestConfigState(serviceUrl: 'http://127.0.0.1:8080', isAuthenticated: true).configured, isTrue);
  });
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
