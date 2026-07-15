import '../../../core/config/api_endpoints_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/github/github_resource_cache.dart';
import '../domain/discover_entities.dart';
import 'discover_cache_codec.dart';

class DiscoverProfileClient {
  const DiscoverProfileClient(this._resources);

  final GitHubResourceCache _resources;

  Future<DataResult<DiscoverProfileEntity>> fetch(String login, DiscoverProfileKind kind) async {
    final result = await _resources.getObject(url: ApiEndpointsConfig.githubPublicUserPath(login));
    return result.map((data) => DiscoverCacheCodec.profileFromJson(data, kind));
  }
}
