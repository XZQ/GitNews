import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/ai_model_providers_config.dart';

void main() {
  group('AiModelProvidersConfig', () {
    test('内置恰好 20 家服务商且 ID 和 Base URL 唯一', () {
      final providers = AiModelProvidersConfig.providers;

      expect(providers, hasLength(20));
      expect(providers.map((item) => item.id).toSet(), hasLength(20));
      expect(providers.map((item) => item.baseUrl).toSet(), hasLength(20));
      expect(providers.every((item) => item.models.contains(item.defaultModel)), isTrue);
    });

    test('Agnes 是默认服务商和默认模型', () {
      final provider = AiModelProvidersConfig.defaultProvider;

      expect(provider.id, 'agnes');
      expect(provider.baseUrl, 'https://apihub.agnes-ai.com/v1');
      expect(provider.defaultModel, 'agnes-2.0-flash');
    });

    test('Base URL 匹配忽略空白、大小写和末尾斜杠', () {
      final provider = AiModelProvidersConfig.findByBaseUrl(' HTTPS://API.DEEPSEEK.COM/// ');

      expect(provider?.id, 'deepseek');
    });
  });
}
