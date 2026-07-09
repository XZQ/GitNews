import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
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
  const GithubProjectRepository({
    required TrendingRepository trending,
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _trending = trending,
        _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final TrendingRepository _trending;
  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;

  static const String _contributorsCacheKey = 'project:github:contributors:v1';

  @override
  Future<ProjectDigest> getDigest() async {
    final trending = await _trending.getDigest();
    final contributors = await _contributorsFor(trending);
    return ProjectDigest(
      repos: trending.allRepos,
      contributors: contributors,
      primaryTrend: trending.primaryTrend,
      secondaryTrend: trending.secondaryTrend,
    );
  }

  Future<List<ContributorEntity>> _contributorsFor(
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
      return cached;
    }
    if (_isRateLimited?.call() ?? false) {
      if (cached.isNotEmpty) {
        return cached;
      }
      return DemoData.contributors.map((e) => e.toEntity()).toList();
    }

    try {
      final repos = digest.allRepos.take(4).map((repo) => repo.fullName);
      final contributors = await _fetchContributors(repos);
      await _cache.upsert(
        key: _contributorsCacheKey,
        payload: {
          'contributors': contributors.map(_contributorToJson).toList(),
        },
        now: now,
      );
      return contributors;
    } catch (e) {
      _maybeReportRateLimit(e);
      AppLogger.warn(
        'githubProjectContributorsFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      if (cached.isNotEmpty) {
        return cached;
      }
      return DemoData.contributors.map((e) => e.toEntity()).toList();
    }
  }

  void _maybeReportRateLimit(Object error) {
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<List<ContributorEntity>> _fetchContributors(
    Iterable<String> repos,
  ) async {
    final results = await gatherAll<List<ContributorEntity>>(
      [
        for (final repo in repos) _fetchRepoContributors(repo),
      ],
      tag: 'githubProjectContributors',
    );
    final byLogin = <String, ContributorEntity>{};
    for (final contributor in results.expand((e) => e)) {
      final old = byLogin[contributor.login];
      byLogin[contributor.login] = ContributorEntity(
        login: contributor.login,
        contributions: (old?.contributions ?? 0) + contributor.contributions,
        avatarAccentArgb: old?.avatarAccentArgb ?? contributor.avatarAccentArgb,
      );
    }
    final contributors = byLogin.values.toList()..sort((a, b) => b.contributions.compareTo(a.contributions));
    return contributors.take(8).toList(growable: false);
  }

  Future<List<ContributorEntity>> _fetchRepoContributors(String repo) async {
    try {
      final response = await _dio.get<List<Object?>>(
        ApiEndpointsConfig.githubRepoContributorsPath(repo),
        queryParameters: const {'per_page': 8},
        options: Options(headers: GitHubApiSupport.headers(token: _token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return data.map(_parseContributor).toList(growable: false);
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
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
