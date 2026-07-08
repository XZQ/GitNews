import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/discover_entities.dart';
import 'discover_seed.dart';

/// 发现页数据仓库。
/// 两个数据源均走「GitHub Search API → 本地缓存 → 种子」三级回退,
/// 与监控/热榜一致的离线路优先策略。
class DiscoverRepository {
  const DiscoverRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;

  static const String _trendingQuery = 'stars:>1000';
  // 按 topic 精准检索 Agent Skills 生态(agent-skills / claude-skills / mcp),
  // 比关键词 OR 命中更相关;stars:>50 过滤掉玩具项目。
  static const String _skillsQuery =
      'topic:agent-skills OR topic:claude-skills OR topic:mcp stars:>50';
  static const String _kTrending = 'discover_trending_repos';
  static const String _kSkills = 'discover_agent_skills';

  Future<List<RepoEntity>> fetchTrendingRepos({bool force = false}) async {
    final now = _now();
    if (force) await _safeDelete(_kTrending);
    if (!_blocked()) {
      if (!force && await _isFresh(_kTrending, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(_kTrending);
        if (cached != null) {
          return _decodeRepos(cached, DataProvenance.freshCache);
        }
      }
      try {
        final repos = await _searchRepos(_trendingQuery, perPage: 20, now: now);
        await _cache.upsert(
          key: _kTrending,
          payload: _repoListToJson(repos),
          now: now,
        );
        return repos;
      } on DioException catch (e) {
        _report(GitHubApiSupport.toAppException(e, now: _now));
      } on AppException catch (e) {
        _report(e);
      } catch (e) {
        AppLogger.warn(
          'discoverTrending',
          meta: {'error': e.runtimeType.toString()},
        );
      }
    }
    final cached = await _cache.read(_kTrending);
    if (cached != null) return _decodeRepos(cached, DataProvenance.staleCache);
    return DiscoverSeed.seedPopularRepos;
  }

  Future<List<SkillEntity>> fetchAgentSkills({bool force = false}) async {
    final now = _now();
    if (force) await _safeDelete(_kSkills);
    if (!_blocked()) {
      if (!force && await _isFresh(_kSkills, CacheTtlConfig.skills, now)) {
        final cached = await _cache.read(_kSkills);
        if (cached != null) {
          return _decodeSkills(cached, DataProvenance.freshCache);
        }
      }
      try {
        final repos = await _searchRepos(_skillsQuery, perPage: 20, now: now);
        final skills = [
          for (var i = 0; i < repos.length; i++)
            SkillEntity(
              repo: repos[i],
              category: _deriveCategory(repos[i]),
              source: 'github_search',
              rank: i + 1,
              summary: repos[i].description,
            ),
        ];
        await _cache.upsert(
          key: _kSkills,
          payload: _skillsToJson(skills),
          now: now,
        );
        return skills;
      } on DioException catch (e) {
        _report(GitHubApiSupport.toAppException(e, now: _now));
      } on AppException catch (e) {
        _report(e);
      } catch (e) {
        AppLogger.warn(
          'discoverSkills',
          meta: {'error': e.runtimeType.toString()},
        );
      }
    }
    final cached = await _cache.read(_kSkills);
    if (cached != null) return _decodeSkills(cached, DataProvenance.staleCache);
    return DiscoverSeed.seedAgentSkills;
  }

  bool _blocked() => _isRateLimited?.call() ?? false;

  Future<bool> _isFresh(String key, Duration ttl, DateTime now) async {
    try {
      return await _cache.isFresh(key: key, ttl: ttl, now: now);
    } catch (_) {
      return false;
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _cache.delete(key);
    } catch (_) {
      // 缓存删除失败不应阻断刷新流程。
    }
  }

  void _report(Object error) {
    AppLogger.warn('discover', meta: {'error': error.runtimeType.toString()});
    if (error is AppException &&
        error.kind == AppExceptionKind.rateLimit &&
        _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<List<RepoEntity>> _searchRepos(
    String q, {
    required int perPage,
    required DateTime now,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubSearchRepositoriesUrl(
        q: q,
        sort: 'stars',
        order: 'desc',
        perPage: perPage,
      ),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) throw const AppException(kind: AppExceptionKind.parse);
    final items = GitHubJson.list(data['items']);
    return [for (final raw in items) _parseSearchRepo(GitHubJson.map(raw))];
  }

  RepoEntity _parseSearchRepo(Map<String, Object?> json) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final description =
        GitHubJson.nullableString(json['description']) ?? 'No description';
    return RepoEntity(
      fullName: fullName,
      description: description,
      language: language,
      starCount: GitHubJson.intValue(json['stargazers_count']),
      starDelta: 0,
      forkCount: GitHubJson.intValue(json['forks_count']),
      accentArgb: GitHubApiSupport.languageColor(language),
      valueProvenance: DataProvenance.live,
      trendProvenance: DataProvenance.live,
    );
  }

  String _deriveCategory(RepoEntity repo) {
    final text = '${repo.fullName} ${repo.description}'.toLowerCase();
    if (text.contains('claude')) return 'claude';
    if (text.contains('cursor')) return 'cursor';
    if (text.contains('copilot')) return 'copilot';
    if (text.contains('mcp')) return 'mcp';
    if (text.contains('langchain') || text.contains('langgraph')) {
      return 'agent';
    }
    return 'other';
  }

  // ---- JSON 编解码 ----

  static Map<String, Object?> _repoToJson(RepoEntity r) => {
        'fullName': r.fullName,
        'description': r.description,
        'language': r.language,
        'starCount': r.starCount,
        'starDelta': r.starDelta,
        'forkCount': r.forkCount,
        'accentArgb': r.accentArgb,
        'valueProvenance': r.valueProvenance.name,
        'trendProvenance': r.trendProvenance.name,
      };

  static Map<String, Object?> _repoListToJson(List<RepoEntity> repos) => {
        'items': [for (final r in repos) _repoToJson(r)],
      };

  static RepoEntity _repoFromJson(
    Map<String, Object?> json,
    DataProvenance p,
  ) =>
      RepoEntity(
        fullName: GitHubJson.string(json['fullName']),
        description: GitHubJson.string(json['description']),
        language: GitHubJson.string(json['language']),
        starCount: GitHubJson.intValue(json['starCount']),
        starDelta: GitHubJson.intValue(json['starDelta']),
        forkCount: GitHubJson.intValue(json['forkCount']),
        accentArgb: GitHubJson.intValue(json['accentArgb']),
        valueProvenance: p,
        trendProvenance: p,
      );

  static List<RepoEntity> _decodeRepos(
    Map<String, Object?> json,
    DataProvenance p,
  ) =>
      [
        for (final raw in GitHubJson.list(json['items']))
          _repoFromJson(GitHubJson.map(raw), p),
      ];

  static Map<String, Object?> _skillsToJson(List<SkillEntity> skills) => {
        'items': [
          for (final s in skills)
            {
              'repo': _repoToJson(s.repo),
              'category': s.category,
              'source': s.source,
              'rank': s.rank,
              'summary': s.summary ?? '',
            },
        ],
      };

  static List<SkillEntity> _decodeSkills(
    Map<String, Object?> json,
    DataProvenance p,
  ) =>
      [
        for (final raw in GitHubJson.list(json['items']))
          _skillFromJson(GitHubJson.map(raw), p),
      ];

  static SkillEntity _skillFromJson(
    Map<String, Object?> json,
    DataProvenance p,
  ) {
    final repoJson = GitHubJson.map(json['repo']);
    return SkillEntity(
      repo: _repoFromJson(repoJson, p),
      category: GitHubJson.string(json['category']),
      source: GitHubJson.string(json['source']),
      rank: GitHubJson.intValue(json['rank']),
      summary: GitHubJson.nullableString(json['summary']),
    );
  }
}
