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
 *白名单抓取结果:成功实体与失败条目数一起返回。
 *
 *调用方需要知道「抓到了几条、还差几条」,否则部分失败会被误标成实时。
 *isStale 表示远端失败后回退了过期缓存,整体新鲜度必须随之降级。
 */
class DiscoverProfileWhitelist {
  const DiscoverProfileWhitelist({required this.profiles, required this.failedCount, this.isStale = false});

  final List<DiscoverProfileEntity> profiles;
  final int failedCount;
  final bool isStale;

  bool get isPartial => failedCount > 0;
}

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
  JsonSnapshotCacheDao? cache,
  DateTime Function()? now,
  bool force = false,
}) async {
  if (page != 1) {
    return DataResult(data: searchResult, freshness: searchFreshness ?? DataFreshness.live);
  }
  final whitelist = await fetchProfileWhitelist(profileClient, kind, cache: cache, now: now, force: force);
  final whitelistLogins = whitelist.profiles.map((p) => p.login).toSet();
  final dedupedSearch = searchResult.where((p) => !whitelistLogins.contains(p.login)).toList();
  final DataFreshness freshness;
  if (whitelist.profiles.isEmpty && searchResult.isEmpty) {
    freshness = DataFreshness.seed;
  } else if (whitelist.isStale) {
    // 白名单回退了过期缓存:无论搜索部分多新鲜,整页不能宣称实时/新鲜缓存。
    freshness = DataFreshness.staleCache;
  } else if (fromCache) {
    freshness = DataFreshness.freshCache;
  } else {
    final base = searchFreshness ?? DataFreshness.live;
    // 白名单有缺失条目时,这一页并不是完整的实时结果,降级为 partial。
    freshness = base == DataFreshness.live && whitelist.isPartial ? DataFreshness.partial : base;
  }
  return DataResult(data: [...whitelist.profiles, ...dedupedSearch], freshness: freshness);
}

/*
 *抓取白名单 profile,带本地缓存层。
 *
 *新鲜缓存命中时零远端请求(此前每次页面缓存命中仍串行发 10 个条件请求);
 *远端并行抓取,全部成功才写缓存;部分失败时优先回退过期缓存并标 isStale,
 *没有缓存才返回缺条目的 partial 结果。
 */
Future<DiscoverProfileWhitelist> fetchProfileWhitelist(
  DiscoverProfileClient profileClient,
  DiscoverProfileKind kind, {
  JsonSnapshotCacheDao? cache,
  DateTime Function()? now,
  bool force = false,
}) async {
  final logins = DiscoverQueries.profileLogins(kind);
  final key = DiscoverQueries.profilesWhitelistKey(kind);
  final currentTime = (now ?? DateTime.now)();
  if (cache != null && !force && await _isFresh(cache, key, CacheTtlConfig.discover, currentTime)) {
    final cached = await _readWhitelistCache(cache, key, kind);
    if (cached != null) {
      return cached;
    }
  }
  final results = await Future.wait([
    for (final login in logins)
      profileClient.fetch(login, kind).then<DiscoverProfileEntity?>((r) => r.data).catchError((Object _) {
        // 单条失败不阻断白名单整体返回;计数交给上层降级标注。
        AppLogger.warn('discover.profileWhitelistEntryFailed', meta: {'kind': kind.name});
        return null;
      }),
  ]);
  final profiles = results.whereType<DiscoverProfileEntity>().toList();
  final failedCount = results.length - profiles.length;
  if (failedCount == 0) {
    if (cache != null) {
      try {
        await cache.upsert(key: key, payload: {...DiscoverCacheCodec.profilesToJson(profiles), 'failedCount': 0}, now: currentTime);
      } catch (_) {
        // 缓存写入失败不影响本次结果。
      }
    }
    return DiscoverProfileWhitelist(profiles: profiles, failedCount: 0);
  }
  if (cache != null) {
    final stale = await _readWhitelistCache(cache, key, kind);
    if (stale != null) {
      return DiscoverProfileWhitelist(profiles: stale.profiles, failedCount: 0, isStale: true);
    }
  }
  return DiscoverProfileWhitelist(profiles: profiles, failedCount: failedCount);
}

Future<DiscoverProfileWhitelist?> _readWhitelistCache(JsonSnapshotCacheDao cache, String key, DiscoverProfileKind kind) async {
  try {
    final cached = await cache.read(key);
    if (cached == null) {
      return null;
    }
    return DiscoverProfileWhitelist(profiles: DiscoverCacheCodec.decodeProfiles(cached, kind), failedCount: GitHubJson.intValue(cached['failedCount']));
  } catch (_) {
    // 坏缓存行删除后按无缓存处理,避免每次启动都复现解码失败。
    try {
      await cache.delete(key);
    } catch (_) {
      // 删除失败不阻断远端回退。
    }
    return null;
  }
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

  // force 只跳过新鲜度检查,不预删缓存:远端失败时仍要回退过期缓存。
  final bool useRemote = !isBlocked();
  List<DiscoverProfileEntity>? searchHits;
  if (useRemote) {
    if (!force && await _isFresh(cache, key, CacheTtlConfig.discover, currentTime)) {
      final cached = await cache.read(key);
      if (cached != null) {
        final cachedList = DiscoverCacheCodec.decodeProfiles(cached, kind);
        return composeProfilesWithWhitelist(profileClient: profileClient, kind: kind, page: page, searchResult: cachedList, fromCache: true, cache: cache, now: now, force: force);
      }
    }
    try {
      final hits = await usersSearchClient.searchUsers(query: searchQuery, page: page, perPage: perPage);
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
      await cache.upsert(key: key, payload: DiscoverCacheCodec.profilesToJson(searchHits), now: currentTime);
    } on DioException catch (e) {
      report(GitHubApiSupport.toAppException(e, now: now));
    } on AppException catch (e) {
      report(e);
    } catch (e) {
      AppLogger.warn('discoverProfilesSearch', meta: {'error': e.runtimeType.toString()});
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
  return composeProfilesWithWhitelist(profileClient: profileClient, kind: kind, page: page, searchResult: searchResult, searchFreshness: searchFreshness, cache: cache, now: now, force: force);
}

Future<bool> _isFresh(JsonSnapshotCacheDao cache, String key, Duration ttl, DateTime now) async {
  try {
    return await cache.isFresh(key: key, ttl: ttl, now: now);
  } catch (_) {
    return false;
  }
}
