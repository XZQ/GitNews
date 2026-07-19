import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/network/dio_client.dart';
import '../data/ai_digest_llm_client.dart';

/*
*资讯详情 AI 解读共用的 OpenAI 兼容请求依赖。
*“我的 AI 日报”已移除,这里只保留逐条资讯增强所需的底层客户端。
*/

final aiDigestDioProvider = Provider<Dio>((ref) => DioClient.create(baseUrl: ApiEndpointsConfig.aiDigestDefaultBaseUrl, headers: const {'Accept': 'application/json'}));

final aiDigestLlmClientProvider = Provider<AiDigestLlmClient>((ref) => AiDigestLlmClient(ref.watch(aiDigestDioProvider)));
