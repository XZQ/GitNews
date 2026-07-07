import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import 'dto/ai_news_item_dto.dart';

/* aihot.virxact.com 公开 REST API 客户端。 */
/*  */
/* 匿名免费、无需 token,但必须带 User-Agent(否则 nginx 直接 403)。 */
/* 实例通过 [AiNewsApiClient.create] 构造时复用上层注入的 [Dio](含统一重试/超时拦截器)。 */
class AiNewsApiClient {
  const AiNewsApiClient._(this._dio);

  /* 用全局拦截器链构造的 [Dio] 注入;只负责 baseUrl 与 UA 头部。 */
  factory AiNewsApiClient.create(Dio dio) {
    return AiNewsApiClient._(dio);
  }

  static const String baseUrl = 'https://aihot.virxact.com';

  static const Map<String, Object?> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'GitHubNews/0.1 (Flutter)',
  };

  final Dio _dio;

  /* `GET /api/public/items`。 */
  /*  */
  /* 参数语义见 [AiNewsRepository.fetchItems]。 */
  Future<AiNewsListResponseDto> fetchItems({
    String? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) async {
    final qp = <String, Object?>{
      'mode': selectedOnly ? 'selected' : 'all',
      if (category != null) 'category': category,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (query != null && query.isNotEmpty) 'q': query,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    try {
      // 复用全局拦截器链;每次请求覆盖 UA(部分上游靠 UA 鉴权)。
      final resp = await _dio.get<Map<String, Object?>>(
        '/api/public/items',
        queryParameters: qp,
        options: Options(headers: _headers),
      );
      final data = resp.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return AiNewsListResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw e.toAppException();
    } on FormatException catch (e, st) {
      // fromJson 解析失败必须经 Repository 边界转换为 AppException,禁止透传 UI。
      throw AppException(
        kind: AppExceptionKind.parse,
        cause: e,
        stack: st,
      );
    } on TypeError catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.parse,
        cause: e,
        stack: st,
      );
    }
  }
}
