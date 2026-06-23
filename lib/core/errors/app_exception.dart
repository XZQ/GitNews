import 'package:dio/dio.dart';

/// 业务异常分类。Repository 在边界将 DataSourceException 转换为 AppException 后再抛出。
enum AppExceptionKind {
  network,
  rateLimit,
  parse,
  notFound,
  unauthorized,
  server,
  unknown,
}

/// 统一业务异常。所有 Notifier / Widget 只应见到 AppException。
class AppException implements Exception {
  const AppException({
    required this.kind,
    this.message,
    this.cause,
    this.stack,
    this.meta = const {},
  });

  final AppExceptionKind kind;

  /// 用户可见的简短消息(可空,UI 层兜底文案)。
  final String? message;

  /// 原始异常。
  final Object? cause;

  /// 原始堆栈。
  final StackTrace? stack;

  /// 额外元数据,例如 429 的 `retryAfter`。
  final Map<String, Object?> meta;

  /// 限流重试倒计时(秒),仅在 [AppExceptionKind.rateLimit] 下有值。
  int? get retryAfterSeconds {
    final v = meta['retryAfter'];
    if (v is int) return v;
    if (v is Duration) return v.inSeconds;
    return null;
  }

  @override
  String toString() => 'AppException($kind, $message)';
}

/// DioException → AppException 扩展,在 Repository 边界调用。
extension DioExceptionToApp on DioException {
  AppException toAppException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException(
          kind: AppExceptionKind.network,
          message: '网络连接超时,请检查网络后重试',
          cause: this,
        );
      case DioExceptionType.badResponse:
        final code = response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          return AppException(
            kind: AppExceptionKind.unauthorized,
            message: '需要登录或权限不足',
            cause: this,
          );
        }
        if (code == 404) {
          return AppException(
            kind: AppExceptionKind.notFound,
            message: '资源不存在',
            cause: this,
          );
        }
        if (code == 429) {
          final ra = response?.headers.value('retry-after');
          final secs = ra == null ? null : int.tryParse(ra);
          return AppException(
            kind: AppExceptionKind.rateLimit,
            message: '请求过于频繁,请稍后再试',
            cause: this,
            meta: {'retryAfter': secs},
          );
        }
        if (code >= 500) {
          return AppException(
            kind: AppExceptionKind.server,
            message: '服务暂不可用',
            cause: this,
          );
        }
        return AppException(
          kind: AppExceptionKind.unknown,
          message: '请求失败($code)',
          cause: this,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AppException(
          kind: AppExceptionKind.unknown,
          message: '未知错误',
          cause: this,
        );
    }
  }
}
