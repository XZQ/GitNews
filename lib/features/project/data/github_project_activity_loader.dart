import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_activity_event.dart';
import '../../../core/domain/repository_feed.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_repo_activity_codec.dart';
import '../../../core/github/github_repo_activity_source.dart';
import '../../../core/github/github_resource_cache.dart';
import '../../../core/network/parallel.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import 'project_cache_keys.dart';

class GithubProjectActivityLoader {
  const GithubProjectActivityLoader({
    required this.cache,
    required this.resources,
    required this.cacheScope,
    required this.now,
    this.isRateLimited,
    this.onRateLimited,
  });

  final JsonSnapshotCacheDao cache;
  final GitHubResourceCache resources;
  final String cacheScope;
  final DateTime Function() now;
  final bool Function()? isRateLimited;
  final void Function(int retryAfterSeconds)? onRateLimited;

  Future<List<RepoActivityEvent>> load(RepositoryFeedDigest digest) async {
    final repos = digest.repos.take(4).map((repo) => repo.fullName).toList(growable: false);
    if (repos.isEmpty) {
      return const [];
    }
    final cacheKey = projectActivitiesCacheKey(repos: repos, cacheScope: cacheScope);
    final cached = await _read(cacheKey);
    if (cached != null && await cache.isFresh(key: cacheKey, ttl: CacheTtlConfig.project, now: now())) {
      return cached;
    }
    if (isRateLimited?.call() ?? false) {
      return cached ?? const [];
    }
    try {
      final results = await gatherAll<DataResult<List<RepoActivityEvent>>>([for (final repo in repos) fetchGitHubRepoActivities(resources: resources, fullName: repo)], tag: 'githubProjectActivities');
      final activities = results.expand((result) => result.data).toList()..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
      final visible = activities.take(30).toList(growable: false);
      await cache.upsert(key: cacheKey, payload: {'activities': repoActivitiesToJson(visible)}, now: now());
      return visible;
    } catch (error) {
      _reportRateLimit(error);
      AppLogger.warn('githubProjectActivitiesFallback', meta: {'error': error.runtimeType.toString()});
      return cached ?? const [];
    }
  }

  Future<List<RepoActivityEvent>?> _read(String cacheKey) async {
    final json = await cache.read(cacheKey);
    if (json == null) {
      return null;
    }
    try {
      return repoActivitiesFromJson(json['activities']);
    } catch (error) {
      AppLogger.warn('githubProjectActivitiesCacheParse', meta: {'error': error.runtimeType.toString()});
      return null;
    }
  }

  void _reportRateLimit(Object error) {
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && onRateLimited != null) {
      onRateLimited!(error.retryAfterSeconds ?? 60);
    }
  }
}
