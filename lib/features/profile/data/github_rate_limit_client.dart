import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';

import '../domain/github_rate_limit.dart';

/* 
*GitHub `/rate_limit` 客户端。
*/
class GitHubRateLimitClient {
  const GitHubRateLimitClient(this._dio);

  final Dio _dio;

  Future<GitHubRateLimitSnapshot> fetch({String? token}) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        ApiEndpointsConfig.githubRateLimitPath,
        options: Options(headers: GitHubApiSupport.headers(token: token)),
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
    if (raw is Map<String, Object?>) {
      return raw;
    }
    throw const FormatException('Expected object');
  }

  int _int(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.round();
    }
    throw const FormatException('Expected int');
  }
}
