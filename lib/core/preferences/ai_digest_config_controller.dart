import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_endpoints_config.dart';
import '../di/providers.dart';

/*
*内置 Agnes 深度解读的凭据状态。
*Key 只由发布构建注入并进入系统安全存储,不向最终用户暴露配置入口。
*/
class AiDigestConfigState {
  const AiDigestConfigState({this.apiKey});

  final String? apiKey;

  bool get configured => apiKey != null && apiKey!.trim().isNotEmpty;
}

/*
*加载发布方注入的 Agnes Key,并清理旧版用户可编辑的服务商配置。
*/
class AiDigestConfigController extends Notifier<AiDigestConfigState> {
  static const _kAgnesSecureKey = 'ai_enrichment_agnes_api_key';
  static const _kLegacySecureKey = 'ai_digest_api_key';
  static const _kLegacyBaseUrlKey = 'ai_digest_base_url';
  static const _kLegacyModelKey = 'ai_digest_model';

  @override
  AiDigestConfigState build() {
    _load();
    return AiDigestConfigState(apiKey: _defaultApiKey);
  }

  Future<void> _load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final secure = ref.read(secureStorageProvider);
    final storedKey = await secure.read(key: _kAgnesSecureKey);
    final key = storedKey ?? _defaultApiKey;
    if (storedKey == null && key != null) {
      await secure.write(key: _kAgnesSecureKey, value: key);
    }
    await secure.delete(key: _kLegacySecureKey);
    await prefs.remove(_kLegacyBaseUrlKey);
    await prefs.remove(_kLegacyModelKey);
    state = AiDigestConfigState(apiKey: key);
  }

  static String? get _defaultApiKey {
    final value = ApiEndpointsConfig.aiDigestDefaultApiKey.trim();
    return value.isEmpty ? null : value;
  }
}

final aiDigestConfigControllerProvider = NotifierProvider<AiDigestConfigController, AiDigestConfigState>(AiDigestConfigController.new);
