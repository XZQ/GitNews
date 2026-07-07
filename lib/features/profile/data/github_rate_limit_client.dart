import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';

/* GitHub rate limit 分桶。 */
class GitHubRateLimitBucket {
  const GitHubRateLimitBucket({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  final int limit;
  final int remaining;
  final DateTime resetAt;
}

/* GitHub rate limit 状态。 */
class GitHubRateLimitSnapshot {
  const GitHubRateLimitSnapshot({
    required this.core,
    required this.search,
    required this.checkedAt,
  });

  final GitHubRateLimitBucket core;
  final GitHubRateLimitBucket search;
  final DateTime checkedAt;
}

/* GitHub `/rate_limit` 客户端。 */
class GitHubRateLimitClient {
  const GitHubRateLimitClient(this._dio);

  final Dio _dio;

  static const Map<String, Object?> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'GitHubNews/0.1 (Flutter)',
  };

  Future<GitHubRateLimitSnapshot> fetch({String? token}) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/rate_limit',
        options: Options(headers: _headersWithAuth(token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      final resources = _map(data['resources']);
      return GitHubRateLimitSnapshot(
        core: _bucket(resources['core']),
        search: _bucket(resources['search']),
        checkedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw e.toAppException();
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  Map<String, Object?> _headersWithAuth(String? token) {
    final trimmed = token?.trim();
    return {
      ..._headers,
      if (trimmed != null && trimmed.isNotEmpty)
        'Authorization': 'Bearer $trimmed',
    };
  }

  GitHubRateLimitBucket _bucket(Object? raw) {
    final json = _map(raw);
    return GitHubRateLimitBucket(
      limit: _int(json['limit']),
      remaining: _int(json['remaining']),
      resetAt: DateTime.fromMillisecondsSinceEpoch(
        _int(json['reset']) * 1000,
        isUtc: true,
      ).toLocal(),
    );
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const FormatException('Expected object');
  }

  int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }
}
