import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/* GitHub REST API 通用请求与解析工具。 */
/*  */
/* Feature 仓库仍负责业务聚合,本文件只收敛跨 feature 重复的协议细节: */
/* headers、Search 查询格式、JSON 类型断言、语言配色和限流异常转换。 */
class GitHubApiSupport {
  const GitHubApiSupport._();

  static const String apiVersion = '2022-11-28';
  static const String userAgent = 'GitHubNews/0.1 (Flutter)';

  static Map<String, Object?> headers({String? token, String? etag}) {
    final trimmed = token?.trim();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': apiVersion,
      'User-Agent': userAgent,
      if (trimmed != null && trimmed.isNotEmpty)
        'Authorization': 'Bearer $trimmed',
      if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
    };
  }

  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String quoteSearchValue(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains(' ')) return trimmed;
    return '"$trimmed"';
  }

  static AppException toAppException(
    DioException e, {
    DateTime Function()? now,
  }) {
    final response = e.response;
    final statusCode = response?.statusCode ?? 0;
    final isGitHubRateLimit = statusCode == 403 &&
        response?.headers.value('x-ratelimit-remaining') == '0';
    if (!isGitHubRateLimit) return e.toAppException();

    final reset = int.tryParse(
      response?.headers.value('x-ratelimit-reset') ?? '',
    );
    final retryAfter = reset == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(reset * 1000)
            .difference((now ?? DateTime.now)())
            .inSeconds
            .clamp(0, 3600);
    return AppException(
      kind: AppExceptionKind.rateLimit,
      cause: e,
      meta: {'retryAfter': retryAfter},
    );
  }

  static int languageColor(String language) {
    return switch (language.toLowerCase()) {
      'typescript' => 0xFF3178C6,
      'javascript' => 0xFFF1E05A,
      'python' => 0xFF3572A5,
      'rust' => 0xFFDEA584,
      'go' => 0xFF00ADD8,
      'dart' => 0xFF00B4AB,
      'kotlin' => 0xFFA97BFF,
      'swift' => 0xFFFA7343,
      'java' => 0xFFB07219,
      'c++' => 0xFFF34B7D,
      'c#' => 0xFF178600,
      _ => 0xFF64748B,
    };
  }

  static int avatarColor(String login) {
    const colors = [
      0xFF0D9488,
      0xFFE5A150,
      0xFF30A46C,
      0xFFE5464D,
      0xFF4CB5FF,
      0xFFA97BFF,
    ];
    final index = login.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return colors[index % colors.length];
  }
}

class GitHubJson {
  const GitHubJson._();

  static List<Object?> list(Object? raw) {
    if (raw is List<Object?>) return raw;
    throw const FormatException('Expected list');
  }

  static Map<String, Object?> map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const FormatException('Expected object');
  }

  static String string(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw const FormatException('Expected string');
  }

  static String? nullableString(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    throw const FormatException('Expected nullable string');
  }

  static int intValue(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }

  static double doubleValue(Object? raw, {double fallback = 0}) {
    if (raw == null) return fallback;
    if (raw is num) return raw.toDouble();
    throw const FormatException('Expected double');
  }

  static List<double> doubleList(Object? raw) {
    return list(raw).map(doubleValue).toList(growable: false);
  }
}
