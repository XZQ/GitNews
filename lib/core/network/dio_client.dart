import 'package:dio/dio.dart';

/// dio 客户端工厂:统一超时与拦截器链。
///
/// 拦截器链:`RetryInterceptor` → 业务拦截器
/// - 5xx / 网络错误重试 2 次,指数退避(500ms / 1500ms)
/// - 429 不重试,把 `Retry-After` 留给异常层处理
class DioClient {
  const DioClient._();

  static Dio create({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://api.github.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ),
    );
    dio.interceptors.add(_RetryInterceptor(dio: dio));
    return dio;
  }
}

class _RetryInterceptor extends Interceptor {
  const _RetryInterceptor({required this.dio});

  final Dio dio;
  static const int maxRetries = 2;
  static const Duration baseDelay = Duration(milliseconds: 500);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retryAttempt'] as int?) ?? 0;
    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = baseDelay * (1 << attempt); // 500ms, 1500ms
    await Future<void>.delayed(delay);

    final req = err.requestOptions..extra['retryAttempt'] = attempt + 1;
    try {
      // Reuse the original dio instance so headers / timeouts / auth are
      // preserved across retries.
      final response = await dio.fetch<dynamic>(req);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        return code >= 500 && code < 600;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
