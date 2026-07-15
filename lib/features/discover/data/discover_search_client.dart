import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import 'discover_cache_codec.dart';

class DiscoverSearchClient {
  const DiscoverSearchClient(this._dio, this._token);

  final Dio _dio;
  final String? _token;

  Future<List<RepoEntity>> search(String query, {required int page, required int perPage}) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubSearchRepositoriesUrl(q: query, sort: 'stars', order: 'desc', perPage: perPage, page: page),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    return [for (final raw in GitHubJson.list(data['items'])) DiscoverCacheCodec.repoFromGitHubSearch(GitHubJson.map(raw))];
  }
}
