import 'api_endpoints_config.dart';

/*
*OpenAI Chat Completions 兼容服务商配置。
*模型列表按 2026-07-16 官方文档或服务商 `/models` 实时结果维护。
*/
class AiModelProviderConfig {
  const AiModelProviderConfig({required this.id, required this.name, required this.baseUrl, required this.models, required this.defaultModel});

  // 稳定标识,用于设置界面的下拉选项。
  final String id;

  // 面向用户展示的服务商品牌名。
  final String name;

  // 不带 `/chat/completions` 的 OpenAI 兼容 Base URL。
  final String baseUrl;

  // 当前可选的文本对话模型 ID。
  final List<String> models;

  // 切换到该服务商时自动选中的模型。
  final String defaultModel;
}

/*
*AI 日报内置服务商目录。
*保持 LongCat 位于首位,使全新安装默认使用美团 LongCat。
*/
class AiModelProvidersConfig {
  const AiModelProvidersConfig._();

  // 自定义 OpenAI 兼容端点的界面选项 ID。
  static const String customProviderId = 'custom';

  // 21 家已核对 OpenAI Chat Completions 兼容性的服务商。
  static const List<AiModelProviderConfig> providers = [
    AiModelProviderConfig(
      id: 'longcat',
      name: 'Meituan LongCat',
      baseUrl: ApiEndpointsConfig.aiDigestDefaultBaseUrl,
      models: ['LongCat-2.0'],
      defaultModel: ApiEndpointsConfig.aiDigestDefaultModel,
    ),
    AiModelProviderConfig(
      id: 'agnes',
      name: 'Agnes AI',
      baseUrl: 'https://apihub.agnes-ai.com/v1',
      models: ['agnes-2.0-flash', 'agnes-1.5-flash'],
      defaultModel: 'agnes-2.0-flash',
    ),
    AiModelProviderConfig(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: ['gpt-5.6', 'gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
      defaultModel: 'gpt-5.6',
    ),
    AiModelProviderConfig(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      models: ['deepseek-v4-flash', 'deepseek-v4-pro'],
      defaultModel: 'deepseek-v4-flash',
    ),
    AiModelProviderConfig(
      id: 'minimax',
      name: 'MiniMax',
      baseUrl: 'https://api.minimaxi.com/v1',
      models: ['MiniMax-M3', 'MiniMax-M2.7', 'MiniMax-M2.7-highspeed'],
      defaultModel: 'MiniMax-M3',
    ),
    AiModelProviderConfig(
      id: 'zai',
      name: 'Z.AI Coding Plan',
      baseUrl: 'https://api.z.ai/api/coding/paas/v4',
      models: ['glm-5.2', 'glm-5.1', 'glm-5-turbo'],
      defaultModel: 'glm-5.2',
    ),
    AiModelProviderConfig(
      id: 'gemini',
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      models: ['gemini-3.5-flash', 'gemini-3.1-pro-preview', 'gemini-3.1-flash-lite'],
      defaultModel: 'gemini-3.5-flash',
    ),
    AiModelProviderConfig(
      id: 'qwen',
      name: 'Alibaba Cloud Qwen',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      models: ['qwen3.7-max', 'qwen3.7-plus', 'qwen3.6-flash'],
      defaultModel: 'qwen3.7-plus',
    ),
    AiModelProviderConfig(
      id: 'moonshot',
      name: 'Moonshot AI / Kimi',
      baseUrl: 'https://api.moonshot.ai/v1',
      models: ['kimi-k2.6', 'kimi-k2-thinking'],
      defaultModel: 'kimi-k2.6',
    ),
    AiModelProviderConfig(
      id: 'openrouter',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      models: ['openrouter/auto', '~openai/gpt-latest'],
      defaultModel: 'openrouter/auto',
    ),
    AiModelProviderConfig(
      id: 'siliconflow',
      name: 'SiliconFlow',
      baseUrl: 'https://api.siliconflow.cn/v1',
      models: ['Pro/zai-org/GLM-5', 'Qwen/Qwen3.5-397B-A17B', 'deepseek-ai/DeepSeek-V3.2'],
      defaultModel: 'Pro/zai-org/GLM-5',
    ),
    AiModelProviderConfig(
      id: 'groq',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      models: ['qwen/qwen3.6-27b', 'openai/gpt-oss-120b', 'llama-3.3-70b-versatile'],
      defaultModel: 'qwen/qwen3.6-27b',
    ),
    AiModelProviderConfig(
      id: 'mistral',
      name: 'Mistral AI',
      baseUrl: 'https://api.mistral.ai/v1',
      models: ['mistral-large-latest', 'mistral-medium-latest', 'mistral-small-latest'],
      defaultModel: 'mistral-large-latest',
    ),
    AiModelProviderConfig(
      id: 'xai',
      name: 'xAI',
      baseUrl: 'https://api.x.ai/v1',
      models: ['grok-4.5', 'grok-4.3-latest', 'grok-420-reasoning'],
      defaultModel: 'grok-4.5',
    ),
    AiModelProviderConfig(
      id: 'perplexity',
      name: 'Perplexity',
      baseUrl: 'https://api.perplexity.ai',
      models: ['sonar-pro', 'sonar', 'sonar-reasoning-pro'],
      defaultModel: 'sonar-pro',
    ),
    AiModelProviderConfig(
      id: 'together',
      name: 'Together AI',
      baseUrl: 'https://api.together.ai/v1',
      models: ['MiniMaxAI/MiniMax-M2.7', 'Qwen/Qwen3.7-Max', 'deepseek-ai/DeepSeek-V4-Pro'],
      defaultModel: 'MiniMaxAI/MiniMax-M2.7',
    ),
    AiModelProviderConfig(
      id: 'fireworks',
      name: 'Fireworks AI',
      baseUrl: 'https://api.fireworks.ai/inference/v1',
      models: ['accounts/fireworks/routers/kimi-k2p6-turbo'],
      defaultModel: 'accounts/fireworks/routers/kimi-k2p6-turbo',
    ),
    AiModelProviderConfig(
      id: 'nvidia',
      name: 'NVIDIA NIM',
      baseUrl: 'https://integrate.api.nvidia.com/v1',
      models: ['nvidia/nemotron-3-ultra-550b-a55b', 'nvidia/nemotron-3-super-120b-a12b', 'deepseek-ai/deepseek-v4-pro'],
      defaultModel: 'nvidia/nemotron-3-super-120b-a12b',
    ),
    AiModelProviderConfig(
      id: 'cerebras',
      name: 'Cerebras',
      baseUrl: 'https://api.cerebras.ai/v1',
      models: ['gpt-oss-120b', 'zai-glm-4.7'],
      defaultModel: 'gpt-oss-120b',
    ),
    AiModelProviderConfig(
      id: 'huggingface',
      name: 'Hugging Face Inference Providers',
      baseUrl: 'https://router.huggingface.co/v1',
      models: ['deepseek-ai/DeepSeek-V4-Pro', 'openai/gpt-oss-120b:fastest'],
      defaultModel: 'deepseek-ai/DeepSeek-V4-Pro',
    ),
    AiModelProviderConfig(
      id: 'cohere',
      name: 'Cohere',
      baseUrl: 'https://api.cohere.ai/compatibility/v1',
      models: ['command-a-plus-05-2026', 'command-a-reasoning-08-2025'],
      defaultModel: 'command-a-plus-05-2026',
    ),
  ];

  /*
  *返回新安装使用的默认美团 LongCat 配置。
  */
  static AiModelProviderConfig get defaultProvider => providers.first;

  /*
  *按稳定 ID 查找服务商。
  */
  static AiModelProviderConfig? findById(String id) {
    for (final provider in providers) {
      if (provider.id == id) {
        return provider;
      }
    }
    return null;
  }

  /*
  *按 Base URL 查找服务商,忽略首尾空白与末尾斜杠。
  */
  static AiModelProviderConfig? findByBaseUrl(String baseUrl) {
    final target = _normalizeBaseUrl(baseUrl);
    for (final provider in providers) {
      if (_normalizeBaseUrl(provider.baseUrl) == target) {
        return provider;
      }
    }
    return null;
  }

  /*
  *生成只用于匹配的规范化 Base URL。
  */
  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }
}
