import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../data/ai_digest_llm_client.dart';

/*
*资讯增强只调用发布方代理；不自动重试付费生成。
*/

final aiDigestDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), sendTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 90)));
  ref.onDispose(dio.close);
  return dio;
});

final aiDigestLlmClientProvider = Provider<AiDigestLlmClient>((ref) => AiDigestLlmClient(ref.watch(aiDigestDioProvider), serviceUrl: ApiEndpointsConfig.aiEnrichmentProxyBaseUrl));
