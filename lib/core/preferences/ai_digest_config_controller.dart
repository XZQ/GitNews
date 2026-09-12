import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session_controller.dart';
import '../config/api_endpoints_config.dart';
import '../di/providers.dart';
import '../network/ai_enrichment_api_support.dart';

/*
*发布方 AI 代理的可用状态，仅保存公开地址和登录状态。
*/
class AiDigestConfigState {
  const AiDigestConfigState({this.serviceUrl = '', this.isAuthenticated = false});

  // 发布方的公开服务 origin。
  final String serviceUrl;

  // 当前用户已登录；Token 不进入本状态。
  final bool isAuthenticated;

  bool get configured => isAuthenticated && AiEnrichmentApiSupport.isAllowedServiceUrl(serviceUrl);
}

/*
*清理旧版客户端共享密钥，只保留服务端代理配置。
*/
class AiDigestConfigController extends Notifier<AiDigestConfigState> {
  static const _kAgnesSecureKey = 'ai_enrichment_agnes_api_key';
  static const _kLegacySecureKey = 'ai_digest_api_key';
  static const _kLegacyBaseUrlKey = 'ai_digest_base_url';
  static const _kLegacyModelKey = 'ai_digest_model';

  @override
  AiDigestConfigState build() {
    _removeLegacyConfig();
    return AiDigestConfigState(serviceUrl: ApiEndpointsConfig.aiEnrichmentProxyBaseUrl.trim(), isAuthenticated: ref.watch(authSessionControllerProvider).isAuthenticated);
  }

  /* 不读取旧密钥内容；清理失败不影响公开资讯。 */
  Future<void> _removeLegacyConfig() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final secure = ref.read(secureStorageProvider);
    try {
      await secure.delete(key: _kAgnesSecureKey);
      await secure.delete(key: _kLegacySecureKey);
      await prefs.remove(_kLegacyBaseUrlKey);
      await prefs.remove(_kLegacyModelKey);
    } catch (_) {
      // 旧密钥不再用于请求；下次加载会再次尝试清理。
    }
  }
}

final aiDigestConfigControllerProvider = NotifierProvider<AiDigestConfigController, AiDigestConfigState>(AiDigestConfigController.new);
