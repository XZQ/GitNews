import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_endpoints_config.dart';
import '../di/providers.dart';

/*
*AI 日报 LLM 配置状态。
*Key 是敏感凭据,与 GitHub Token 同级:只进 secure storage,
*不进日志、导出配置和源码;baseUrl / model 是非敏感偏好,走 prefs。
*/
class AiDigestConfigState {
  const AiDigestConfigState({
    this.apiKey,
    this.baseUrl = ApiEndpointsConfig.aiDigestDefaultBaseUrl,
    this.model = ApiEndpointsConfig.aiDigestDefaultModel,
  });

  final String? apiKey;
  final String baseUrl;
  final String model;

  bool get configured => apiKey != null && apiKey!.trim().isNotEmpty;

  String get maskedKey {
    final raw = apiKey?.trim();
    if (raw == null || raw.isEmpty) {
      return '';
    }
    if (raw.length <= 8) {
      return '已配置';
    }
    return '${raw.substring(0, 4)}...${raw.substring(raw.length - 4)}';
  }
}

/*
*AI 日报 LLM 配置 controller(OpenAI 兼容端点)。
*/
class AiDigestConfigController extends Notifier<AiDigestConfigState> {
  static const _kSecureKey = 'ai_digest_api_key';
  static const _kBaseUrlKey = 'ai_digest_base_url';
  static const _kModelKey = 'ai_digest_model';

  @override
  AiDigestConfigState build() {
    _load();
    return const AiDigestConfigState();
  }

  Future<void> _load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final secure = ref.read(secureStorageProvider);
    final key = await secure.read(key: _kSecureKey);
    state = AiDigestConfigState(
      apiKey: key,
      baseUrl: prefs.getString(_kBaseUrlKey) ?? ApiEndpointsConfig.aiDigestDefaultBaseUrl,
      model: prefs.getString(_kModelKey) ?? ApiEndpointsConfig.aiDigestDefaultModel,
    );
  }

  Future<void> save({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final secure = ref.read(secureStorageProvider);
    final trimmedKey = apiKey.trim();
    final trimmedBase = _normalizeBaseUrl(baseUrl);
    final trimmedModel = model.trim().isEmpty ? ApiEndpointsConfig.aiDigestDefaultModel : model.trim();
    if (trimmedKey.isEmpty) {
      await secure.delete(key: _kSecureKey);
    } else {
      await secure.write(key: _kSecureKey, value: trimmedKey);
    }
    await prefs.setString(_kBaseUrlKey, trimmedBase);
    await prefs.setString(_kModelKey, trimmedModel);
    state = AiDigestConfigState(
      apiKey: trimmedKey.isEmpty ? null : trimmedKey,
      baseUrl: trimmedBase,
      model: trimmedModel,
    );
  }

  static String _normalizeBaseUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return ApiEndpointsConfig.aiDigestDefaultBaseUrl;
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

final aiDigestConfigControllerProvider = NotifierProvider<AiDigestConfigController, AiDigestConfigState>(
  AiDigestConfigController.new,
);
