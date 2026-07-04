import 'package:dio/dio.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/repo_detail_repository.dart';
import 'local_repo_detail_repository.dart';

const Duration repoDetailRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub REST API 的仓库详情仓库。
class GithubRepoDetailRepository implements RepoDetailRepository {
  const GithubRepoDetailRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    RepoDetailRepository fallback = const LocalRepoDetailRepository(),
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final RepoDetailRepository _fallback;

  @override
  Future<RepoDetailDigest> getDetail(String fullName) async {
    final decoded = Uri.decodeComponent(fullName);
    final cacheKey = _cacheKey(decoded);
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
    final repo = await _fetchRepo(fullName, now);
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
      primaryTrend: repo.trend ?? _repoTrend(repo.starCount, 1),
      compareTrend: _repoTrend(repo.starCount, 0.72),
    );
  }

  Future<RepoEntity> _fetchRepo(String fullName, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: _headers()),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _parseRepo(data, now);
    } on DioException catch (e) {
      throw e.toAppException();
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
        options: Options(headers: _headers()),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return data.map(_parseContributor).toList(growable: false);
    } on DioException catch (e) {
      throw e.toAppException();
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
          : ' language:${_quoteIfNeeded(repo.language)}';
      final response = await _dio.get<Map<String, Object?>>(
        '/search/repositories',
        queryParameters: {
          'q':
              '${repo.fullName.split('/').last} in:name,description stars:>30 archived:false$language',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 6,
        },
        options: Options(headers: _headers()),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _list(data['items'])
          .map((raw) => _parseRepo(_map(raw), _now()))
          .where((item) => item.fullName != repo.fullName)
          .take(4)
          .toList(growable: false);
    } on DioException catch (e) {
      throw e.toAppException();
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  RepoEntity _parseRepo(Map<String, Object?> json, DateTime now) {
    final fullName = _string(json['full_name']);
    final language = _nullableString(json['language']) ?? 'Unknown';
    final stars = _int(json['stargazers_count']);
    final forks = _int(json['forks_count']);
    final issues = _int(json['open_issues_count']);
    final pushedAt = DateTime.tryParse(_string(json['pushed_at']))?.toUtc();
    return RepoEntity(
      fullName: fullName,
      description: _nullableString(json['description']) ?? 'No description',
      language: language,
      starCount: stars,
      starDelta: _activityScore(
        stars: stars,
        forks: forks,
        issues: issues,
        pushedAt: pushedAt,
        now: now,
      ),
      forkCount: forks,
      accentArgb: _languageColor(language),
      trend: _repoTrend(stars, 1),
    );
  }

  ContributorEntity _parseContributor(Object? raw) {
    final json = _map(raw);
    final login = _string(json['login']);
    return ContributorEntity(
      login: login,
      contributions: _int(json['contributions']),
      avatarAccentArgb: _avatarColor(login),
    );
  }

  int _activityScore({
    required int stars,
    required int forks,
    required int issues,
    required DateTime? pushedAt,
    required DateTime now,
  }) {
    final pushedBoost = pushedAt == null
        ? 1
        : (30 - now.toUtc().difference(pushedAt).inDays).clamp(1, 30);
    return ((stars / 180) + (forks / 35) + (issues / 16) + pushedBoost)
        .round()
        .clamp(1, 9999);
  }

  List<double> _repoTrend(int stars, double scale) {
    final base = stars / 150 * scale;
    return List<double>.generate(
      7,
      (index) => (base * (0.72 + index * 0.06)).roundToDouble(),
    );
  }

  String _cacheKey(String fullName) {
    return 'repo_detail:github:${fullName.toLowerCase()}:v1';
  }

  Map<String, Object?> _headers() {
    final token = _token?.trim();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'GitHubNews/0.1 (Flutter)',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _quoteIfNeeded(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains(' ')) return trimmed;
    return '"$trimmed"';
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
      contributors:
          _list(json['contributors']).map(_contributorFromJson).toList(),
      relatedRepos: _list(json['relatedRepos']).map(_repoFromJson).toList(),
      primaryTrend: _list(json['primaryTrend']).map(_double).toList(),
      compareTrend: _list(json['compareTrend']).map(_double).toList(),
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
      'trend': repo.trend,
    };
  }

  RepoEntity _repoFromJson(Object? raw) {
    final json = _map(raw);
    return RepoEntity(
      fullName: _string(json['fullName']),
      description: _string(json['description']),
      language: _string(json['language']),
      starCount: _int(json['starCount']),
      starDelta: _int(json['starDelta']),
      forkCount: _int(json['forkCount']),
      accentArgb: _int(json['accentArgb']),
      trend: json['trend'] == null
          ? null
          : _list(json['trend']).map(_double).toList(growable: false),
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
    final json = _map(raw);
    return ContributorEntity(
      login: _string(json['login']),
      contributions: _int(json['contributions']),
      avatarAccentArgb: _int(json['avatarAccentArgb']),
    );
  }

  List<Object?> _list(Object? raw) {
    if (raw is List<Object?>) return raw;
    throw const FormatException('Expected list');
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const FormatException('Expected object');
  }

  String _string(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw const FormatException('Expected string');
  }

  String? _nullableString(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    throw const FormatException('Expected nullable string');
  }

  int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }

  double _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    throw const FormatException('Expected double');
  }

  int _languageColor(String language) {
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

  int _avatarColor(String login) {
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
