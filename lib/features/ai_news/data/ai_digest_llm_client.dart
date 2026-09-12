import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_enrichment_api_support.dart';
import '../domain/ai_news_item.dart';

/*
*调用发布方的受限资讯增强接口，不接受任意提示词或模型密钥。
*/
class AiDigestLlmClient {
  const AiDigestLlmClient(this._dio, {required this.serviceUrl});

  // 不配置自动重试，避免重复计费。
  final Dio _dio;

  // 公开服务地址。
  final String serviceUrl;

  /* 只提交文章字段与用户会话，禁止重定向携带认证头。 */
  Future<String> enrich({required String accessToken, required AiNewsItem item}) async {
    if (!AiEnrichmentApiSupport.isAllowedServiceUrl(serviceUrl) || accessToken.trim().isEmpty) {
      throw const AppException(kind: AppExceptionKind.unauthorized);
    }
    try {
      final response = await _dio.post<Map<String, Object?>>(
        Uri.parse(serviceUrl.trim()).resolve(ApiEndpointsConfig.aiEnrichmentPath).toString(),
        data: {'title': item.title, 'title_en': item.titleEn, 'summary': item.summary, 'source': item.source, 'url': item.url},
        options: Options(headers: AiEnrichmentApiSupport.headers(accessToken), followRedirects: false, maxRedirects: 0),
      );
      final data = response.data;
      if (data == null || data['model'] != ApiEndpointsConfig.aiDigestDefaultModel || data['enrichment'] is! Map) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return jsonEncode(data['enrichment']);
    } on DioException catch (error) {
      // 不保留携带用户认证头的原始网络异常。
      throw AppException(kind: error.toAppException().kind);
    }
  }
}
