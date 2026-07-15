import 'package:dio/dio.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/discover_entities.dart';
import 'discover_cache_codec.dart';
import 'discover_profile_client.dart';
import 'discover_queries.dart';
import 'discover_users_search_client.dart';

typedef DiscoverProfileReport = void Function(Object error);

/*
 *仅 page==1 时,在搜索结果前置白名单(enriched),并对与白名单重复的 login 去重。
 */
Future<DataResult<List<DiscoverProfileEntity>>> composeProfilesWithWhitelist({
  required DiscoverProfileClient profileClient,
  required DiscoverProfileKind kind,
  required int page,
  required List<DiscoverProfileEntity> searchResult,
  DataFreshness? searchFreshness,
  bool fromCache = false,
}) async {
  if (page != 1) {
    return DataResult(
      data: searchResult,
      freshness: searchFreshness ?? DataFreshness.live,
    );
  }
  final whitelist = await fetchProfileWhitelist(profileClient, kind);
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

Future<List<DiscoverProfileEntity>> fetchProfileWhitelist(
  DiscoverProfileClient profileClient,
  DiscoverProfileKind kind,
) async {
  final logins = DiscoverQueries.profileLogins(kind);
  final results = <DiscoverProfileEntity>[];
  for (final login in logins) {
    try {
      final r = await profileClient.fetch(login, kind);
      results.add(r.data);
    } catch (_) {
      // 单条失败不阻断白名单整体返回;跳过。
    }
  }
  return results;
}

/*
 *拉取一页 profile 搜索结果并与白名单合成。
 *
 *把 profile 的搜索 + 缓存 + 白名单合成链路从主仓库中分离,
 *让 `DiscoverRepository` 仅做依赖装配与委托。
 */
Future<DataResult<List<DiscoverProfileEntity>>> fetchProfilesPage({
  required DiscoverProfileClient profileClient,
  required DiscoverUsersSearchClient usersSearchClient,
  required JsonSnapshotCacheDao cache,
  required DateTime Function() now,
  required bool Function() isBlocked,
  required DiscoverProfileReport report,
  required DiscoverProfileKind kind,
  bool force = false,
  int page = 1,
  int perPage = 20,
}) async {
  final currentTime = now();
  final searchQuery = kind == DiscoverProfileKind.official ? DiscoverQueries.officialSearchQuery : DiscoverQueries.peopleSearchQuery;
  final key = DiscoverQueries.profilesPageKey(kind, page, perPage);

  if (force) {
    await _safeDelete(cache, key);
  }

  final bool useRemote = !isBlocked();
  List<DiscoverProfileEntity>? searchHits;
  if (useRemote) {
    if (!force && await _isFresh(cache, key, CacheTtlConfig.discover, currentTime)) {
      final cached = await cache.read(key);
      if (cached != null) {
        final cachedList = DiscoverCacheCodec.decodeProfiles(cached, kind);
        return composeProfilesWithWhitelist(
          profileClient: profileClient,
          kind: kind,
          page: page,
          searchResult: cachedList,
          fromCache: true,
        );
      }
    }
    try {
      final hits = await usersSearchClient.searchUsers(
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
      await cache.upsert(
        key: key,
        payload: DiscoverCacheCodec.profilesToJson(searchHits),
        now: currentTime,
      );
    } on DioException catch (e) {
      report(GitHubApiSupport.toAppException(e, now: now));
    } on AppException catch (e) {
      report(e);
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
    final cached = await cache.read(key);
    if (cached != null) {
      searchResult = DiscoverCacheCodec.decodeProfiles(cached, kind);
      searchFreshness = DataFreshness.staleCache;
    } else {
      searchResult = const [];
      searchFreshness = page == 1 ? DataFreshness.seed : DataFreshness.staleCache;
    }
  }
  return composeProfilesWithWhitelist(
    profileClient: profileClient,
    kind: kind,
    page: page,
    searchResult: searchResult,
    searchFreshness: searchFreshness,
  );
}

Future<void> _safeDelete(JsonSnapshotCacheDao cache, String key) async {
  try {
    await cache.delete(key);
  } catch (_) {
    // 缓存删除失败不应阻断刷新流程。
  }
}

Future<bool> _isFresh(JsonSnapshotCacheDao cache, String key, Duration ttl, DateTime now) async {
  try {
    return await cache.isFresh(key: key, ttl: ttl, now: now);
  } catch (_) {
    return false;
  }
}
