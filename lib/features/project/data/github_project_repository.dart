import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/github/github_resource_cache.dart';
import '../../../core/network/parallel.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../../trending/domain/trending_repository.dart';
import '../domain/project_repository.dart';

const Duration projectRemoteCacheTtl = CacheTtlConfig.project;

/* 
*基于趋势仓库 + GitHub contributors 的深度报告仓库。
*/
class GithubProjectRepository implements ProjectRepository {
  GithubProjectRepository({
    required TrendingRepository trending,
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    String cacheScope = 'anonymous',
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _trending = trending,
        _cache = cache,
        _resources = GitHubResourceCache(
          dio: dio,
          cache: cache,
          token: token,
          cacheScope: cacheScope,
          now: now,
        ),
        _now = now ?? DateTime.now,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final TrendingRepository _trending;
  final JsonSnapshotCacheDao _cache;
  final GitHubResourceCache _resources;
  final DateTime Function() _now;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;

  static const String _contributorsCacheKey = 'project:github:contributors:v1';

  @override
  Future<DataResult<ProjectDigest>> getDigest() async {
    final trendingResult = await _trending.getDigest();
    final trending = trendingResult.data;
    final contributorResult = await _contributorsFor(trending);
    return DataResult(
      freshness: _leastFresh(
        trendingResult.freshness,
        contributorResult.freshness,
      ),
      data: ProjectDigest(
        repos: trending.allRepos,
        contributors: contributorResult.data,
        primaryTrend: trending.primaryTrend,
        secondaryTrend: trending.secondaryTrend,
      ),
    );
  }

  Future<DataResult<List<ContributorEntity>>> _contributorsFor(
    TrendingDigest digest,
  ) async {
    final now = _now();
    final cached = await _readContributors();
    if (cached.isNotEmpty &&
        await _cache.isFresh(
          key: _contributorsCacheKey,
          ttl: projectRemoteCacheTtl,
          now: now,
        )) {
      return DataResult(
        data: cached,
        freshness: DataFreshness.freshCache,
      );
    }
    if (_isRateLimited?.call() ?? false) {
      if (cached.isNotEmpty) {
        return DataResult(
          data: cached,
          freshness: DataFreshness.staleCache,
        );
      }
      return DataResult(
        data: DemoData.contributors.map((e) => e.toEntity()).toList(),
        freshness: DataFreshness.seed,
      );
    }

    try {
      final repos = digest.allRepos.take(4).map((repo) => repo.fullName);
      final result = await _fetchContributors(repos);
      final contributors = result.data;
      await _cache.upsert(
        key: _contributorsCacheKey,
        payload: {
          'contributors': contributors.map(_contributorToJson).toList(),
        },
        now: now,
      );
      return DataResult(data: contributors, freshness: result.freshness);
    } catch (e) {
      _maybeReportRateLimit(e);
      AppLogger.warn(
        'githubProjectContributorsFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      if (cached.isNotEmpty) {
        return DataResult(
          data: cached,
          freshness: DataFreshness.staleCache,
        );
      }
      return DataResult(
        data: DemoData.contributors.map((e) => e.toEntity()).toList(),
        freshness: DataFreshness.seed,
      );
    }
  }

  void _maybeReportRateLimit(Object error) {
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<DataResult<List<ContributorEntity>>> _fetchContributors(
    Iterable<String> repos,
  ) async {
    final results = await gatherAll<DataResult<List<ContributorEntity>>>(
      [
        for (final repo in repos) _fetchRepoContributors(repo),
      ],
      tag: 'githubProjectContributors',
    );
    final byLogin = <String, ContributorEntity>{};
    for (final contributor in results.expand((result) => result.data)) {
      final old = byLogin[contributor.login];
      byLogin[contributor.login] = ContributorEntity(
        login: contributor.login,
        contributions: (old?.contributions ?? 0) + contributor.contributions,
        avatarAccentArgb: old?.avatarAccentArgb ?? contributor.avatarAccentArgb,
      );
    }
    final contributors = byLogin.values.toList()..sort((a, b) => b.contributions.compareTo(a.contributions));
    return DataResult(
      data: contributors.take(8).toList(growable: false),
      freshness: results.every(
        (result) => result.freshness == DataFreshness.freshCache,
      )
          ? DataFreshness.freshCache
          : DataFreshness.live,
    );
  }

  Future<DataResult<List<ContributorEntity>>> _fetchRepoContributors(
    String repo,
  ) async {
    try {
      final result = await _resources.getList(
        url: ApiEndpointsConfig.githubRepoContributorsPath(repo),
        queryParameters: const {'per_page': 8},
      );
      return result.map(
        (data) => data.map(_parseContributor).toList(growable: false),
      );
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  ContributorEntity _parseContributor(Object? raw) {
    final json = GitHubJson.map(raw);
    final login = GitHubJson.string(json['login']);
    return ContributorEntity(
      login: login,
      contributions: GitHubJson.intValue(json['contributions']),
      avatarAccentArgb: GitHubApiSupport.avatarColor(login),
    );
  }

  Future<List<ContributorEntity>> _readContributors() async {
    final json = await _cache.read(_contributorsCacheKey);
    if (json == null) {
      return const [];
    }
    try {
      return GitHubJson.list(
        json['contributors'],
      ).map(_contributorFromJson).toList(growable: false);
    } catch (e) {
      AppLogger.warn(
        'githubProjectContributorsCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return const [];
    }
  }

  Map<String, Object?> _contributorToJson(ContributorEntity contributor) {
    return {
      'login': contributor.login,
      'contributions': contributor.contributions,
      'avatarAccentArgb': contributor.avatarAccentArgb,
    };
  }

  ContributorEntity _contributorFromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return ContributorEntity(
      login: GitHubJson.string(json['login']),
      contributions: GitHubJson.intValue(json['contributions']),
      avatarAccentArgb: GitHubJson.intValue(json['avatarAccentArgb']),
    );
  }
}

DataFreshness _leastFresh(DataFreshness left, DataFreshness right) {
  const priority = {
    DataFreshness.live: 0,
    DataFreshness.freshCache: 1,
    DataFreshness.staleCache: 2,
    DataFreshness.seed: 3,
  };
  return priority[left]! >= priority[right]! ? left : right;
}
