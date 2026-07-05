import 'package:dio/dio.dart';

import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/repo_detail_repository.dart';
import 'github_repo_detail_helpers.dart';
import 'local_repo_detail_repository.dart';

const Duration repoDetailRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub REST API 的仓库详情仓库。
class GithubRepoDetailRepository implements RepoDetailRepository {
  const GithubRepoDetailRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    RepoSnapshotHistoryDao? snapshotHistory,
    String? token,
    DateTime Function()? now,
    RepoDetailRepository fallback = const LocalRepoDetailRepository(),
  })  : _dio = dio,
        _cache = cache,
        _snapshotHistory = snapshotHistory,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final RepoSnapshotHistoryDao? _snapshotHistory;
  final String? _token;
  final DateTime Function() _now;
  final RepoDetailRepository _fallback;

  @override
  Future<RepoDetailDigest> getDetail(String fullName) async {
    final decoded = Uri.decodeComponent(fullName);
    final cacheKey = repoDetailCacheKey(decoded);
    final now = _now();
    final cached = await _readCached(cacheKey);
    if (cached != null &&
        await _cache.isFresh(
          key: cacheKey,
          ttl: repoDetailRemoteCacheTtl,
          now: now,
        )) {
      return cached;
    }

    try {
      final digest = await _fetchDetail(decoded, now);
      await _cache.upsert(
        key: cacheKey,
        payload: _digestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      AppLogger.warn(
        'githubRepoDetailFallback',
        meta: {'repo': decoded, 'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDetail(decoded);
    }
  }

  Future<RepoDetailDigest?> _readCached(String cacheKey) async {
    final json = await _cache.read(cacheKey);
    if (json == null) return null;
    try {
      return _digestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubRepoDetailCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<RepoDetailDigest> _fetchDetail(String fullName, DateTime now) async {
    final repo = await _withHistoryTrend(await _fetchRepo(fullName, now), now);
    final results = await Future.wait([
      _fetchContributors(fullName),
      _fetchRelatedRepos(repo),
    ]);
    final contributors = results[0] as List<ContributorEntity>;
    final relatedRepos = results[1] as List<RepoEntity>;
    return RepoDetailDigest(
      repo: repo,
      contributors: contributors,
      relatedRepos: relatedRepos,
      primaryTrend: repo.trend ?? estimatedRepoTrend(repo.starCount, 1),
      compareTrend: estimatedRepoTrend(repo.starCount, 0.72),
    );
  }

  Future<RepoEntity> _withHistoryTrend(RepoEntity repo, DateTime now) async {
    final history = _snapshotHistory;
    if (history == null) return repo;
    await history.record(
      fullName: repo.fullName,
      stars: repo.starCount,
      forks: repo.forkCount,
      capturedAt: now,
    );
    final starTrend = await history.starTrend(repo.fullName);
    if (starTrend == null) return repo;
    return repo.copyWith(
      starDelta: _observedDelta(starTrend.values, fallback: repo.starDelta),
      trend: starTrend.values,
      trendProvenance: starTrend.provenance,
    );
  }

  int _observedDelta(List<double> values, {required int fallback}) {
    if (values.length < 2) return fallback;
    final delta = values.last - values.first;
    return delta.round().clamp(0, 999999);
  }

  Future<RepoEntity> _fetchRepo(String fullName, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _parseRepo(data, now);
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  Future<List<ContributorEntity>> _fetchContributors(String fullName) async {
    try {
      final response = await _dio.get<List<Object?>>(
        '/repos/$fullName/contributors',
        queryParameters: const {'per_page': 12},
        options: Options(headers: GitHubApiSupport.headers(_token)),
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

  Future<List<RepoEntity>> _fetchRelatedRepos(RepoEntity repo) async {
    try {
      final language = repo.language == 'Unknown'
          ? ''
          : ' language:${GitHubApiSupport.quoteSearchValue(repo.language)}';
      final response = await _dio.get<Map<String, Object?>>(
        '/search/repositories',
        queryParameters: {
          'q':
              '${repo.fullName.split('/').last} in:name,description stars:>30 archived:false$language',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 6,
        },
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return GitHubJson.list(data['items'])
          .map((raw) => _parseRepo(GitHubJson.map(raw), _now()))
          .where((item) => item.fullName != repo.fullName)
          .take(4)
          .toList(growable: false);
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  RepoEntity _parseRepo(Map<String, Object?> json, DateTime now) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final stars = GitHubJson.intValue(json['stargazers_count']);
    final forks = GitHubJson.intValue(json['forks_count']);
    final issues = GitHubJson.intValue(json['open_issues_count']);
    final pushedAt =
        DateTime.tryParse(GitHubJson.string(json['pushed_at']))?.toUtc();
    return RepoEntity(
      fullName: fullName,
      description:
          GitHubJson.nullableString(json['description']) ?? 'No description',
      language: language,
      starCount: stars,
      starDelta: repoDetailActivityScore(
        stars: stars,
        forks: forks,
        issues: issues,
        pushedAt: pushedAt,
        now: now,
      ),
      forkCount: forks,
      accentArgb: GitHubApiSupport.languageColor(language),
      valueProvenance: DataProvenance.observed,
      trendProvenance: DataProvenance.estimated,
      trend: estimatedRepoTrend(stars, 1),
    );
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

  Map<String, Object?> _digestToJson(RepoDetailDigest digest) {
    return {
      'repo': _repoToJson(digest.repo),
      'contributors': digest.contributors.map(_contributorToJson).toList(),
      'relatedRepos': digest.relatedRepos.map(_repoToJson).toList(),
      'primaryTrend': digest.primaryTrend,
      'compareTrend': digest.compareTrend,
    };
  }

  RepoDetailDigest _digestFromJson(Map<String, Object?> json) {
    return RepoDetailDigest(
      repo: _repoFromJson(json['repo']),
      contributors: GitHubJson.list(json['contributors'])
          .map(_contributorFromJson)
          .toList(),
      relatedRepos:
          GitHubJson.list(json['relatedRepos']).map(_repoFromJson).toList(),
      primaryTrend: GitHubJson.doubleList(json['primaryTrend']),
      compareTrend: GitHubJson.doubleList(json['compareTrend']),
    );
  }

  Map<String, Object?> _repoToJson(RepoEntity repo) {
    return {
      'fullName': repo.fullName,
      'description': repo.description,
      'language': repo.language,
      'starCount': repo.starCount,
      'starDelta': repo.starDelta,
      'forkCount': repo.forkCount,
      'accentArgb': repo.accentArgb,
      'valueProvenance': repo.valueProvenance.name,
      'trendProvenance': repo.trendProvenance.name,
      'trend': repo.trend,
    };
  }

  RepoEntity _repoFromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return RepoEntity(
      fullName: GitHubJson.string(json['fullName']),
      description: GitHubJson.string(json['description']),
      language: GitHubJson.string(json['language']),
      starCount: GitHubJson.intValue(json['starCount']),
      starDelta: GitHubJson.intValue(json['starDelta']),
      forkCount: GitHubJson.intValue(json['forkCount']),
      accentArgb: GitHubJson.intValue(json['accentArgb']),
      valueProvenance: DataProvenance.fromName(
        GitHubJson.nullableString(json['valueProvenance']),
      ),
      trendProvenance: DataProvenance.fromName(
        GitHubJson.nullableString(json['trendProvenance']),
      ),
      trend:
          json['trend'] == null ? null : GitHubJson.doubleList(json['trend']),
    );
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
