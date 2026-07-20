import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/network/dio_client.dart';
import '../data/ai_digest_llm_client.dart';

/*
*资讯详情 AI 解读共用的内置 Agnes 请求依赖。
*最终用户不配置服务商、模型或 Key。
*/

final aiDigestDioProvider = Provider<Dio>((ref) => DioClient.create(baseUrl: ApiEndpointsConfig.aiDigestDefaultBaseUrl, headers: const {'Accept': 'application/json'}));

final aiDigestLlmClientProvider = Provider<AiDigestLlmClient>((ref) => AiDigestLlmClient(ref.watch(aiDigestDioProvider)));
