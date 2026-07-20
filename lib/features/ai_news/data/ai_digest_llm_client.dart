import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/errors/app_exception.dart';

/*
*内置 Agnes Chat Completions 客户端。
*端点和模型固定使用应用内置值;失败以 [AppException] 抛出,
*绝不返回伪造的摘要文本。Key 只出现在请求头,不写日志。
*/
class AiDigestLlmClient {
  const AiDigestLlmClient(this._dio);

  final Dio _dio;

  /*
  *执行一次补全,返回首个 choice 的文本。
  */
  Future<String> complete({required String apiKey, required String systemPrompt, required String userPrompt}) async {
    final Response<Map<String, Object?>> resp;
    try {
      resp = await _dio.post<Map<String, Object?>>(
        ApiEndpointsConfig.aiDigestChatCompletionsUrl,
        data: {
          'model': ApiEndpointsConfig.aiDigestDefaultModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          // LLM 生成耗时远超普通 API,单独放宽接收超时。
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } on DioException catch (e) {
      throw e.toAppException();
    }
    final data = resp.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    try {
      final choices = data['choices'] as List?;
      final first = choices?.first as Map<String, Object?>?;
      final message = first?['message'] as Map<String, Object?>?;
      final content = _extractContent(message?['content']);
      if (content == null || content.trim().isEmpty) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return content.trim();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  /*
  *兼容字符串正文与部分服务商返回的文本分段数组。
  */
  static String? _extractContent(Object? raw) {
    if (raw is String) {
      return raw;
    }
    if (raw is! List) {
      return null;
    }
    final parts = <String>[];
    for (final part in raw) {
      if (part is String) {
        parts.add(part);
      } else if (part is Map<String, Object?> && part['text'] is String) {
        parts.add(part['text']! as String);
      }
    }
    return parts.join();
  }
}
