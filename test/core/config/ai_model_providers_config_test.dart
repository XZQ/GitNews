import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/ai_model_providers_config.dart';

void main() {
  group('AiModelProvidersConfig', () {
    test('内置恰好 21 家服务商且 ID 和 Base URL 唯一', () {
      final providers = AiModelProvidersConfig.providers;

      expect(providers, hasLength(21));
      expect(providers.map((item) => item.id).toSet(), hasLength(21));
      expect(providers.map((item) => item.baseUrl).toSet(), hasLength(21));
      expect(providers.every((item) => item.models.contains(item.defaultModel)), isTrue);
    });

    test('LongCat 是默认服务商和默认模型', () {
      final provider = AiModelProvidersConfig.defaultProvider;

      expect(provider.id, 'longcat');
      expect(provider.baseUrl, 'https://api.longcat.chat/openai');
      expect(provider.defaultModel, 'LongCat-2.0');
    });

    test('Base URL 匹配忽略空白、大小写和末尾斜杠', () {
      final provider = AiModelProvidersConfig.findByBaseUrl(' HTTPS://API.DEEPSEEK.COM/// ');

      expect(provider?.id, 'deepseek');
    });

    test('LongCat 使用实测可用的 Base URL 和模型', () {
      final provider = AiModelProvidersConfig.findById('longcat');

      expect(provider?.name, 'Meituan LongCat');
      expect(provider?.baseUrl, 'https://api.longcat.chat/openai');
      expect(provider?.models, ['LongCat-2.0']);
      expect(provider?.defaultModel, 'LongCat-2.0');
    });
  });
}
