import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import 'user_search_hit.dart';

class DiscoverUsersSearchClient {
  const DiscoverUsersSearchClient(this._dio, this._token);

  final Dio _dio;
  final String? _token;

  Future<List<UserSearchHit>> searchUsers({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubSearchUsersUrl(
        q: query,
        perPage: perPage,
        page: page,
      ),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    final items = data['items'];
    if (items is! List<Object?>) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    return [
      for (final raw in items) _hitFromJson(GitHubJson.map(raw)),
    ];
  }

  UserSearchHit _hitFromJson(Map<String, Object?> json) {
    return UserSearchHit(
      login: GitHubJson.string(json['login']),
      avatarUrl: GitHubJson.nullableString(json['avatar_url']) ?? '',
      htmlUrl: GitHubJson.nullableString(json['html_url']) ?? '',
      type: GitHubJson.nullableString(json['type']) ?? 'User',
    );
  }
}
