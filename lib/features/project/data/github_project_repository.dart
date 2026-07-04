import 'package:dio/dio.dart';

import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../../trending/domain/trending_repository.dart';
import '../domain/project_repository.dart';

const Duration projectRemoteCacheTtl = Duration(minutes: 5);

/// 基于趋势仓库 + GitHub contributors 的深度报告仓库。
class GithubProjectRepository implements ProjectRepository {
  const GithubProjectRepository({
    required TrendingRepository trending,
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
  })  : _trending = trending,
        _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now;

  final TrendingRepository _trending;
  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;

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
      AppLogger.warn(
        'githubProjectContributorsFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      if (cached.isNotEmpty) return cached;
      return DemoData.contributors.map((e) => e.toEntity()).toList();
    }
  }

  Future<List<ContributorEntity>> _fetchContributors(
    Iterable<String> repos,
  ) async {
    final results = await Future.wait([
      for (final repo in repos) _fetchRepoContributors(repo),
    ]);
    final byLogin = <String, ContributorEntity>{};
    for (final contributor in results.expand((e) => e)) {
      final old = byLogin[contributor.login];
      byLogin[contributor.login] = ContributorEntity(
        login: contributor.login,
        contributions: (old?.contributions ?? 0) + contributor.contributions,
        avatarAccentArgb: old?.avatarAccentArgb ?? contributor.avatarAccentArgb,
      );
    }
    final contributors = byLogin.values.toList()
      ..sort((a, b) => b.contributions.compareTo(a.contributions));
    return contributors.take(8).toList(growable: false);
  }

  Future<List<ContributorEntity>> _fetchRepoContributors(String repo) async {
    try {
      final response = await _dio.get<List<Object?>>(
        '/repos/$repo/contributors',
        queryParameters: const {'per_page': 8},
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

  ContributorEntity _parseContributor(Object? raw) {
    final json = _map(raw);
    final login = _string(json['login']);
    return ContributorEntity(
      login: login,
      contributions: _int(json['contributions']),
      avatarAccentArgb: _avatarColor(login),
    );
  }

  Future<List<ContributorEntity>> _readContributors() async {
    final json = await _cache.read(_contributorsCacheKey);
    if (json == null) return const [];
    try {
      return _list(json['contributors'])
          .map(_contributorFromJson)
          .toList(growable: false);
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
    final json = _map(raw);
    return ContributorEntity(
      login: _string(json['login']),
      contributions: _int(json['contributions']),
      avatarAccentArgb: _int(json['avatarAccentArgb']),
    );
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

  int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }
}
