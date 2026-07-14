import 'package:dio/dio.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/github/github_resource_cache.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/discover_entities.dart';
import 'discover_cache_codec.dart';
import 'discover_profile_client.dart';
import 'discover_queries.dart';
import 'discover_search_client.dart';
import 'discover_seed.dart';
import 'discover_users_search_client.dart';

/// 发现页数据仓库。
/// 两个数据源均走「GitHub Search API → 本地缓存 → 种子」三级回退,
/// 与监控/热榜一致的离线路优先策略。
class DiscoverRepository {
  DiscoverRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    String cacheScope = 'anonymous',
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _cache = cache,
        _searchClient = DiscoverSearchClient(dio, token),
        _usersSearchClient = DiscoverUsersSearchClient(dio, token),
        _profileClient = DiscoverProfileClient(
          GitHubResourceCache(
            dio: dio,
            cache: cache,
            token: token,
            cacheScope: cacheScope,
            now: now,
          ),
        ),
        _now = now ?? DateTime.now,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final JsonSnapshotCacheDao _cache;
  final DiscoverSearchClient _searchClient;
  final DiscoverUsersSearchClient _usersSearchClient;
  final DiscoverProfileClient _profileClient;
  final DateTime Function() _now;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;

  Future<DataResult<List<RepoEntity>>> fetchTrendingRepos({
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final now = _now();
    final key = DiscoverQueries.pageKey(
      DiscoverQueries.trendingCache,
      page,
      perPage,
    );
    if (force) {
      await _safeDelete(key);
    }
    if (!_blocked()) {
      if (!force && await _isFresh(key, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          return DataResult(
            data: DiscoverCacheCodec.decodeRepos(cached),
            freshness: DataFreshness.freshCache,
          );
        }
      }
      try {
        final repos = await _searchClient.search(
          DiscoverQueries.trending,
          page: page,
          perPage: perPage,
        );
        await _cache.upsert(
          key: key,
          payload: DiscoverCacheCodec.repoListToJson(repos),
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
        data: DiscoverCacheCodec.decodeRepos(cached),
        freshness: DataFreshness.staleCache,
      );
    }
    return DataResult(
      data: DiscoverQueries.slice(
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
    final key = DiscoverQueries.pageKey(
      DiscoverQueries.skillsCache,
      page,
      perPage,
    );
    if (force) {
      await _safeDelete(key);
    }
    if (!_blocked()) {
      if (!force && await _isFresh(key, CacheTtlConfig.skills, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          return DataResult(
            data: DiscoverCacheCodec.decodeSkills(cached),
            freshness: DataFreshness.freshCache,
          );
        }
      }
      try {
        final repos = await _searchClient.search(
          DiscoverQueries.skills,
          page: page,
          perPage: perPage,
        );
        final offset = (page - 1) * perPage;
        final skills = [
          for (var i = 0; i < repos.length; i++)
            SkillEntity(
              repo: repos[i],
              category: DiscoverQueries.deriveSkillCategory(repos[i]),
              source: 'github_search',
              rank: offset + i + 1,
              summary: repos[i].description,
            ),
        ];
        await _cache.upsert(
          key: key,
          payload: DiscoverCacheCodec.skillsToJson(skills),
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
        data: DiscoverCacheCodec.decodeSkills(cached),
        freshness: DataFreshness.staleCache,
      );
    }
    return DataResult(
      data: DiscoverQueries.slice(
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
    int page = 1,
    int perPage = 20,
  }) async {
    final now = _now();
    final searchQuery = kind == DiscoverProfileKind.official ? DiscoverQueries.officialSearchQuery : DiscoverQueries.peopleSearchQuery;
    final key = DiscoverQueries.profilesPageKey(kind, page, perPage);

    if (force) {
      await _safeDelete(key);
    }

    final bool useRemote = !_blocked();
    List<DiscoverProfileEntity>? searchHits;
    if (useRemote) {
      if (!force && await _isFresh(key, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          final cachedList = DiscoverCacheCodec.decodeProfiles(cached, kind);
          return _composeWithWhitelist(
            kind,
            page,
            cachedList,
            fromCache: true,
          );
        }
      }
      try {
        final hits = await _usersSearchClient.searchUsers(
          query: searchQuery,
          page: page,
          perPage: perPage,
        );
        searchHits = [
          for (final hit in hits)
            DiscoverProfileEntity(
              login: hit.login,
              name: hit.login,
              type: hit.type,
              bio: '',
              publicRepos: 0,
              followers: 0,
              avatarUrl: hit.avatarUrl,
              htmlUrl: hit.htmlUrl,
              featuredRepoFullName: DiscoverQueries.featuredRepoForLogin(hit.login),
              kind: kind,
              enriched: false,
              enrichFailed: false,
            ),
        ];
        await _cache.upsert(
          key: key,
          payload: DiscoverCacheCodec.profilesToJson(searchHits),
          now: now,
        );
      } on DioException catch (e) {
        _report(GitHubApiSupport.toAppException(e, now: _now));
      } on AppException catch (e) {
        _report(e);
      } catch (e) {
        AppLogger.warn(
          'discoverProfilesSearch',
          meta: {'error': e.runtimeType.toString()},
        );
      }
    }

    final List<DiscoverProfileEntity> searchResult;
    final DataFreshness searchFreshness;
    if (searchHits != null) {
      searchResult = searchHits;
      searchFreshness = DataFreshness.live;
    } else {
      final cached = await _cache.read(key);
      if (cached != null) {
        searchResult = DiscoverCacheCodec.decodeProfiles(cached, kind);
        searchFreshness = DataFreshness.staleCache;
      } else {
        searchResult = const [];
        searchFreshness = page == 1 ? DataFreshness.seed : DataFreshness.staleCache;
      }
    }
    return _composeWithWhitelist(
      kind,
      page,
      searchResult,
      searchFreshness: searchFreshness,
    );
  }

  /// 仅 page==1 时,在搜索结果前置白名单(enriched),并对与白名单重复的 login 去重。
  Future<DataResult<List<DiscoverProfileEntity>>> _composeWithWhitelist(
    DiscoverProfileKind kind,
    int page,
    List<DiscoverProfileEntity> searchResult, {
    DataFreshness? searchFreshness,
    bool fromCache = false,
  }) async {
    if (page != 1) {
      return DataResult(
        data: searchResult,
        freshness: searchFreshness ?? DataFreshness.live,
      );
    }
    final whitelist = await _fetchWhitelist(kind);
    final whitelistLogins = whitelist.map((p) => p.login).toSet();
    final dedupedSearch = searchResult.where((p) => !whitelistLogins.contains(p.login)).toList();
    final DataFreshness freshness;
    if (whitelist.isEmpty && searchResult.isEmpty) {
      freshness = DataFreshness.seed;
    } else if (fromCache) {
      freshness = DataFreshness.freshCache;
    } else {
      freshness = searchFreshness ?? DataFreshness.live;
    }
    return DataResult(
      data: [...whitelist, ...dedupedSearch],
      freshness: freshness,
    );
  }

  Future<List<DiscoverProfileEntity>> _fetchWhitelist(
    DiscoverProfileKind kind,
  ) async {
    final logins = DiscoverQueries.profileLogins(kind);
    final results = <DiscoverProfileEntity>[];
    for (final login in logins) {
      try {
        final r = await _profileClient.fetch(login, kind);
        results.add(r.data);
      } catch (_) {
        // 单条失败不阻断白名单整体返回;跳过。
      }
    }
    return results;
  }

  Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({
    required String login,
    required DiscoverProfileKind kind,
  }) async {
    final result = await _profileClient.fetch(login, kind);
    return result.map((p) => p.copyWith());
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
}
