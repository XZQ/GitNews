import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../storage/cache_meta_dao.dart';

/*
*AI HOT 公开接口的协议常量与异常转换。
*User-Agent 使用可识别的非浏览器标识,遵循公开 API 的边缘安全合同。
*/
class AiHotApiSupport {
  const AiHotApiSupport._();

  // AI HOT 要求的可识别非浏览器 User-Agent。
  static const String userAgent = 'GitNews/1.5 (+https://github.com/XZQ/GitNews)';

  // REST JSON 响应类型。
  static const String jsonAccept = 'application/json';

  // RSS/Atom/XML 响应类型。
  static const String feedAccept = 'application/rss+xml, application/atom+xml, application/xml, text/xml';

  /* 构造普通或条件 GET 请求头。 */
  static Map<String, Object?> headers({
    required String accept,
    HttpCacheValidators validators = const HttpCacheValidators(),
  }) {
    return {
      'Accept': accept,
      'User-Agent': userAgent,
      if (validators.etag case final String etag when etag.isNotEmpty) 'If-None-Match': etag,
      if (validators.lastModified case final String lastModified when lastModified.isNotEmpty) 'If-Modified-Since': lastModified,
    };
  }

  /* 把 AI HOT 网络异常转为项目统一异常。 */
  static AppException toAppException(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    if (statusCode == 567) {
      final body = error.response?.data;
      final json = body is Map ? body.cast<String, Object?>() : const <String, Object?>{};
      return AppException(
        kind: AppExceptionKind.server,
        cause: error,
        meta: {
          'statusCode': statusCode,
          if (json['requestId'] case final String requestId) 'requestId': requestId,
          if (json['help'] case final String help) 'help': help,
        },
      );
    }
    if (statusCode == 429 && error.response?.headers.value('retry-after') == null) {
      return AppException(
        kind: AppExceptionKind.rateLimit,
        cause: error,
        meta: {'retryAfter': 30},
      );
    }
    return error.toAppException();
  }
}
