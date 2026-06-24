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
    this.cause,
    this.stack,
    this.meta = const {},
  });

  final AppExceptionKind kind;

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
  String toString() => 'AppException($kind)';
}

/// DioException → AppException 扩展,在 Repository 边界调用。
///
/// 文案由 UI 层根据 [kind] 通过 i18n key 渲染(见 [ErrorView])。
extension DioExceptionToApp on DioException {
  AppException toAppException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException(
          kind: AppExceptionKind.network,
          cause: this,
        );
      case DioExceptionType.badResponse:
        final code = response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          return AppException(
            kind: AppExceptionKind.unauthorized,
            cause: this,
          );
        }
        if (code == 404) {
          return AppException(
            kind: AppExceptionKind.notFound,
            cause: this,
          );
        }
        if (code == 429) {
          final ra = response?.headers.value('retry-after');
          final secs = ra == null ? null : int.tryParse(ra);
          return AppException(
            kind: AppExceptionKind.rateLimit,
            cause: this,
            meta: {'retryAfter': secs},
          );
        }
        if (code >= 500) {
          return AppException(
            kind: AppExceptionKind.server,
            cause: this,
            meta: {'statusCode': code},
          );
        }
        return AppException(
          kind: AppExceptionKind.unknown,
          cause: this,
          meta: {'statusCode': code},
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AppException(
          kind: AppExceptionKind.unknown,
          cause: this,
        );
    }
  }
}
