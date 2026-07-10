import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
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
  static const String _skillsQuery = 'topic:agent-skills OR topic:claude-skills OR topic:mcp stars:>50';
  static const String _kTrending = 'discover_trending_repos';
  static const String _kSkills = 'discover_agent_skills';
  static const String _kProfiles = 'discover_profiles';
  static const List<String> _officialLogins = [
    'openai',
    'anthropics',
    'microsoft',
    'langchain-ai',
    'crewAIInc',
    'modelcontextprotocol',
    'vercel',
    'google',
    'meta-llama',
    'huggingface',
  ];
  static const List<String> _peopleLogins = [
    'karpathy',
    'simonw',
    'swyxio',
    'hwchase17',
    'jerryjliu',
    'gdb',
    'fchollet',
    'soumith',
    'TimDettmers',
    'shreyashankar',
  ];
  static const Map<String, String> _featuredReposByLogin = {
    'openai': 'openai/openai-agents-python',
    'anthropics': 'anthropics/skills',
    'microsoft': 'microsoft/autogen',
    'langchain-ai': 'langchain-ai/langchain',
    'crewAIInc': 'crewAIInc/crewAI',
    'modelcontextprotocol': 'modelcontextprotocol/servers',
    'vercel': 'vercel/ai',
    'google': 'google-gemini/gemini-cli',
    'meta-llama': 'meta-llama/llama-cookbook',
    'huggingface': 'huggingface/transformers',
    'karpathy': 'karpathy/nanoGPT',
    'simonw': 'simonw/llm',
    'swyxio': 'swyxio/ai-notes',
    'hwchase17': 'langchain-ai/langchain',
    'jerryjliu': 'run-llama/llama_index',
    'gdb': 'openai/openai-cookbook',
    'fchollet': 'keras-team/keras',
    'soumith': 'pytorch/pytorch',
    'TimDettmers': 'bitsandbytes-foundation/bitsandbytes',
    'shreyashankar': 'lotus-data/lotus',
  };

  Future<DataResult<List<RepoEntity>>> fetchTrendingRepos({
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final now = _now();
    final key = _pageKey(_kTrending, page, perPage);
    if (force) {
      await _safeDelete(key);
    }
    if (!_blocked()) {
      if (!force && await _isFresh(key, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          return DataResult(
            data: _decodeRepos(cached),
            freshness: DataFreshness.freshCache,
          );
        }
      }
      try {
        final repos = await _searchRepos(
          _trendingQuery,
          page: page,
          perPage: perPage,
          now: now,
        );
        await _cache.upsert(
          key: key,
          payload: _repoListToJson(repos),
          now: now,
        );
        return DataResult(data: repos, freshness: DataFreshness.live);
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
    final cached = await _cache.read(key);
    if (cached != null) {
      return DataResult(
        data: _decodeRepos(cached),
        freshness: DataFreshness.staleCache,
      );
    }
    return DataResult(
      data: _slice(
        DiscoverSeed.seedPopularRepos,
        page: page,
        perPage: perPage,
      ),
      freshness: DataFreshness.seed,
    );
  }

  Future<DataResult<List<SkillEntity>>> fetchAgentSkills({
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final now = _now();
    final key = _pageKey(_kSkills, page, perPage);
    if (force) {
      await _safeDelete(key);
    }
    if (!_blocked()) {
      if (!force && await _isFresh(key, CacheTtlConfig.skills, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          return DataResult(
            data: _decodeSkills(cached),
            freshness: DataFreshness.freshCache,
          );
        }
      }
      try {
        final repos = await _searchRepos(
          _skillsQuery,
          page: page,
          perPage: perPage,
          now: now,
        );
        final offset = (page - 1) * perPage;
        final skills = [
          for (var i = 0; i < repos.length; i++)
            SkillEntity(
              repo: repos[i],
              category: _deriveCategory(repos[i]),
              source: 'github_search',
              rank: offset + i + 1,
              summary: repos[i].description,
            ),
        ];
        await _cache.upsert(
          key: key,
          payload: _skillsToJson(skills),
          now: now,
        );
        return DataResult(data: skills, freshness: DataFreshness.live);
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
    final cached = await _cache.read(key);
    if (cached != null) {
      return DataResult(
        data: _decodeSkills(cached),
        freshness: DataFreshness.staleCache,
      );
    }
    return DataResult(
      data: _slice(
        DiscoverSeed.seedAgentSkills,
        page: page,
        perPage: perPage,
      ),
      freshness: DataFreshness.seed,
    );
  }

  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
  }) async {
    final now = _now();
    final key = '$_kProfiles:${kind.name}';
    if (force) {
      await _safeDelete(key);
    }
    if (!_blocked()) {
      if (!force && await _isFresh(key, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          return DataResult(
            data: _decodeProfiles(cached, kind),
            freshness: DataFreshness.freshCache,
          );
        }
      }
      try {
        final profiles = <DiscoverProfileEntity>[];
        for (final login in _profileLogins(kind)) {
          profiles.add(await _fetchProfile(login, kind));
        }
        await _cache.upsert(
          key: key,
          payload: _profilesToJson(profiles),
          now: now,
        );
        return DataResult(data: profiles, freshness: DataFreshness.live);
      } on DioException catch (e) {
        _report(GitHubApiSupport.toAppException(e, now: _now));
      } on AppException catch (e) {
        _report(e);
      } catch (e) {
        AppLogger.warn(
          'discoverProfiles',
          meta: {'error': e.runtimeType.toString()},
        );
      }
    }
    final cached = await _cache.read(key);
    if (cached != null) {
      return DataResult(
        data: _decodeProfiles(cached, kind),
        freshness: DataFreshness.staleCache,
      );
    }
    return DataResult(
      data: DiscoverSeed.seedProfiles(kind),
      freshness: DataFreshness.seed,
    );
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
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<List<RepoEntity>> _searchRepos(
    String q, {
    required int page,
    required int perPage,
    required DateTime now,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubSearchRepositoriesUrl(
        q: q,
        sort: 'stars',
        order: 'desc',
        perPage: perPage,
        page: page,
      ),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    final items = GitHubJson.list(data['items']);
    return [for (final raw in items) _parseSearchRepo(GitHubJson.map(raw))];
  }

  Future<DiscoverProfileEntity> _fetchProfile(
    String login,
    DiscoverProfileKind kind,
  ) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubPublicUserPath(login),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    return _profileFromJson(data, kind);
  }

  RepoEntity _parseSearchRepo(Map<String, Object?> json) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final description = GitHubJson.nullableString(json['description']) ?? 'No description';
    return RepoEntity(
      fullName: fullName,
      description: description,
      language: language,
      starCount: GitHubJson.intValue(json['stargazers_count']),
      starDelta: 0,
      forkCount: GitHubJson.intValue(json['forks_count']),
      accentArgb: GitHubApiSupport.languageColor(language),
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.estimated,
    );
  }

  String _deriveCategory(RepoEntity repo) {
    final text = '${repo.fullName} ${repo.description}'.toLowerCase();
    if (text.contains('claude')) {
      return 'claude';
    }
    if (text.contains('cursor')) {
      return 'cursor';
    }
    if (text.contains('copilot')) {
      return 'copilot';
    }
    if (text.contains('mcp')) {
      return 'mcp';
    }
    if (text.contains('langchain') || text.contains('langgraph')) {
      return 'agent';
    }
    return 'other';
  }

  static String _pageKey(String base, int page, int perPage) => '$base:p$page:n$perPage';

  static List<String> _profileLogins(DiscoverProfileKind kind) => kind == DiscoverProfileKind.official ? _officialLogins : _peopleLogins;

  static String _featuredRepoForLogin(String login) => _featuredReposByLogin[login] ?? '$login/$login';

  static List<T> _slice<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;
    if (start >= items.length) {
      return const [];
    }
    final end = (start + perPage).clamp(0, items.length);
    return items.sublist(start, end);
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
        'valueBasis': r.valueBasis.name,
        'trendBasis': r.trendBasis.name,
      };

  static Map<String, Object?> _repoListToJson(List<RepoEntity> repos) => {
        'items': [for (final r in repos) _repoToJson(r)],
      };

  static RepoEntity _repoFromJson(Map<String, Object?> json) => RepoEntity(
        fullName: GitHubJson.string(json['fullName']),
        description: GitHubJson.string(json['description']),
        language: GitHubJson.string(json['language']),
        starCount: GitHubJson.intValue(json['starCount']),
        starDelta: GitHubJson.intValue(json['starDelta']),
        forkCount: GitHubJson.intValue(json['forkCount']),
        accentArgb: GitHubJson.intValue(json['accentArgb']),
        valueBasis: _basisFromJson(json, 'valueBasis', 'valueProvenance'),
        trendBasis: _basisFromJson(json, 'trendBasis', 'trendProvenance'),
      );

  static List<RepoEntity> _decodeRepos(Map<String, Object?> json) => [
        for (final raw in GitHubJson.list(json['items'])) _repoFromJson(GitHubJson.map(raw)),
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

  static List<SkillEntity> _decodeSkills(Map<String, Object?> json) => [
        for (final raw in GitHubJson.list(json['items'])) _skillFromJson(GitHubJson.map(raw)),
      ];

  static SkillEntity _skillFromJson(Map<String, Object?> json) {
    final repoJson = GitHubJson.map(json['repo']);
    return SkillEntity(
      repo: _repoFromJson(repoJson),
      category: GitHubJson.string(json['category']),
      source: GitHubJson.string(json['source']),
      rank: GitHubJson.intValue(json['rank']),
      summary: GitHubJson.nullableString(json['summary']),
    );
  }

  static MetricBasis _basisFromJson(
    Map<String, Object?> json,
    String key,
    String legacyKey,
  ) {
    final name = GitHubJson.nullableString(json[key]);
    return name == null
        ? MetricBasis.fromLegacyName(
            GitHubJson.nullableString(json[legacyKey]),
          )
        : MetricBasis.fromName(name);
  }

  static Map<String, Object?> _profileToJson(DiscoverProfileEntity p) => {
        'login': p.login,
        'name': p.name,
        'type': p.type,
        'bio': p.bio,
        'publicRepos': p.publicRepos,
        'followers': p.followers,
        'avatarUrl': p.avatarUrl,
        'htmlUrl': p.htmlUrl,
        'featuredRepoFullName': p.featuredRepoFullName,
      };

  static Map<String, Object?> _profilesToJson(
    List<DiscoverProfileEntity> profiles,
  ) =>
      {
        'items': [for (final p in profiles) _profileToJson(p)],
      };

  static List<DiscoverProfileEntity> _decodeProfiles(
    Map<String, Object?> json,
    DiscoverProfileKind kind,
  ) =>
      [
        for (final raw in GitHubJson.list(json['items'])) _profileFromJson(GitHubJson.map(raw), kind),
      ];

  static DiscoverProfileEntity _profileFromJson(
    Map<String, Object?> json,
    DiscoverProfileKind kind,
  ) {
    final login = GitHubJson.string(json['login']);
    final name = GitHubJson.nullableString(json['name']);
    return DiscoverProfileEntity(
      login: login,
      name: (name == null || name.isEmpty) ? login : name,
      type: GitHubJson.nullableString(json['type']) ?? (kind == DiscoverProfileKind.official ? 'Organization' : 'User'),
      bio: GitHubJson.nullableString(json['bio']) ?? '',
      publicRepos: GitHubJson.intValue(json['public_repos'] ?? json['publicRepos']),
      followers: GitHubJson.intValue(json['followers']),
      avatarUrl: GitHubJson.nullableString(json['avatar_url']) ?? GitHubJson.nullableString(json['avatarUrl']) ?? '',
      htmlUrl: GitHubJson.nullableString(json['html_url']) ?? GitHubJson.nullableString(json['htmlUrl']) ?? 'https://github.com/$login',
      featuredRepoFullName: GitHubJson.nullableString(json['featuredRepoFullName']) ?? _featuredRepoForLogin(login),
      kind: kind,
    );
  }
}
