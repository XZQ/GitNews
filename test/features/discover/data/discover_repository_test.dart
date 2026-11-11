import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/discover/data/discover_queries.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final Map<String, Object?> Function(RequestOptions options) _responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final payload = _responder(options);
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/* 让指定白名单 login 返回 500,用于验证「部分成功」的降级标注。 */
class _PartialFailureAdapter implements HttpClientAdapter {
  _PartialFailureAdapter({required this.failingLogin});

  final String failingLogin;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.path;
    if (path.endsWith('/users/$failingLogin')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'boom'}),
        500,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final Object payload = path.contains('/search/users')
        ? {
            'items': [
              {'login': 'some-new-org', 'avatar_url': '', 'html_url': '', 'type': 'Organization'},
            ],
          }
        : {'login': path.split('/').last, 'name': path.split('/').last, 'type': 'Organization', 'bio': 'bio', 'public_repos': 5, 'followers': 10, 'avatar_url': '', 'html_url': ''};
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  late LocalDatabase db;
  late JsonSnapshotCacheDao cache;

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor));
  });

  tearDown(() async {
    await db.close();
  });

  DiscoverRepository buildRepo(Dio dio) => DiscoverRepository(dio: dio, cache: cache, now: () => DateTime.utc(2026, 7, 14));

  group('fetchProfiles 分页', () {
    test('page=1 返回白名单(enriched) + 搜索结果(占位)', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {'login': 'some-new-org', 'avatar_url': 'https://github.com/some-new-org.png', 'html_url': 'https://github.com/some-new-org', 'type': 'Organization'},
            ],
          };
        }
        // /users/{login} — used by whitelist enrichment
        return {
          'login': options.path.split('/').last,
          'name': options.path.split('/').last,
          'type': 'Organization',
          'bio': 'bio',
          'public_repos': 5,
          'followers': 9999,
          'avatar_url': 'https://github.com/x.png',
          'html_url': 'https://github.com/x',
        };
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      final whitelistCount = DiscoverQueries.officialLogins.length;
      expect(result.data.length, whitelistCount + 1);
      final whitelist = result.data.take(whitelistCount).toList();
      expect(whitelist.every((p) => p.enriched), isTrue);
      final searchHit = result.data.last;
      expect(searchHit.login, 'some-new-org');
      expect(searchHit.enriched, isFalse);
      expect(result.freshness, DataFreshness.live);
    });

    test('白名单条目部分失败时 freshness 降级为 partial', () async {
      final dio = Dio();
      dio.httpClientAdapter = _PartialFailureAdapter(failingLogin: 'openai');
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      expect(result.freshness, DataFreshness.partial);
      expect(result.data.any((p) => p.login == 'openai'), isFalse);
      expect(result.data.where((p) => p.enriched).length, DiscoverQueries.officialLogins.length - 1);
    });

    test('page=2 只返回搜索结果,不含白名单', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'items': [
            {'login': 'page2-org', 'avatar_url': '', 'html_url': '', 'type': 'Organization'},
          ],
        };
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 2, perPage: 20);

      expect(result.data.length, 1);
      expect(result.data.single.login, 'page2-org');
      expect(result.data.single.enriched, isFalse);
    });

    test('搜索结果与白名单 login 重复时去重,保留 enriched 版本', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {
                'login': 'openai', // 白名单已有
                'avatar_url': '',
                'html_url': '',
                'type': 'Organization',
              },
            ],
          };
        }
        return {'login': options.path.split('/').last, 'name': 'OpenAI', 'type': 'Organization', 'bio': 'bio', 'public_repos': 100, 'followers': 200, 'avatar_url': '', 'html_url': ''};
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      final openaiEntries = result.data.where((p) => p.login == 'openai');
      expect(openaiEntries.length, 1);
      expect(openaiEntries.single.enriched, isTrue);
    });
  });

  group('fetchProfileDetail', () {
    test('透传 login/kind 给 profile client,返回 enriched 实体', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {'login': 'karpathy', 'name': 'Andrej Karpathy', 'type': 'User', 'bio': 'researcher', 'public_repos': 60, 'followers': 200000, 'avatar_url': '', 'html_url': ''};
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfileDetail(login: 'karpathy', kind: DiscoverProfileKind.people);

      expect(result.data.login, 'karpathy');
      expect(result.data.enriched, isTrue);
      expect(result.data.followers, 200000);
    });
  });

  group('缓存与刷新回退', () {
    Dio buildProfilesDio() {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {'login': 'some-new-org', 'avatar_url': '', 'html_url': '', 'type': 'Organization'},
            ],
          };
        }
        return {
          'login': options.path.split('/').last,
          'name': options.path.split('/').last,
          'type': 'Organization',
          'bio': 'bio',
          'public_repos': 5,
          'followers': 10,
          'avatar_url': '',
          'html_url': '',
        };
      });
      return dio;
    }

    test('缓存读回保留搜索占位的未补全状态', () async {
      final repo = buildRepo(buildProfilesDio());
      await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      final cached = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      expect(cached.freshness, DataFreshness.freshCache);
      expect(cached.data.last.enriched, isFalse);
    });

    test('新鲜缓存命中时白名单不再发远端请求', () async {
      final repo = buildRepo(buildProfilesDio());
      await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      final offline = Dio();
      offline.httpClientAdapter = _StubAdapter((options) {
        throw StateError('新鲜缓存命中不应触达远端: ${options.path}');
      });
      final cached = await buildRepo(offline).fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      expect(cached.freshness, DataFreshness.freshCache);
      expect(cached.data.length, DiscoverQueries.officialLogins.length + 1);
    });

    test('force 刷新失败回退过期缓存而不是种子', () async {
      final repo = buildRepo(buildProfilesDio());
      final live = await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);
      expect(live.freshness, DataFreshness.live);

      final failing = Dio();
      failing.httpClientAdapter = _StubAdapter((options) {
        throw StateError('offline');
      });
      final later = DiscoverRepository(dio: failing, cache: cache, now: () => DateTime.utc(2026, 7, 14, 7));
      final refreshed = await later.fetchProfiles(kind: DiscoverProfileKind.official, force: true, page: 1, perPage: 20);

      expect(refreshed.freshness, DataFreshness.staleCache);
      expect(refreshed.data.length, live.data.length);
    });

    test('白名单部分失败时回退过期缓存并整体降级 staleCache', () async {
      final repo = buildRepo(buildProfilesDio());
      await repo.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      final partial = Dio();
      partial.httpClientAdapter = _PartialFailureAdapter(failingLogin: 'openai');
      final later = DiscoverRepository(dio: partial, cache: cache, now: () => DateTime.utc(2026, 7, 14, 7));
      final result = await later.fetchProfiles(kind: DiscoverProfileKind.official, page: 1, perPage: 20);

      expect(result.freshness, DataFreshness.staleCache);
      expect(result.data.where((p) => p.enriched).length, DiscoverQueries.officialLogins.length);
    });

    test('force 刷新仓库列表失败保留过期缓存', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'items': [
            {'full_name': 'owner/repo', 'description': 'd', 'language': 'Dart', 'stargazers_count': 100, 'forks_count': 1},
          ],
        };
      });
      final repo = buildRepo(dio);
      final live = await repo.fetchTrendingRepos(page: 1, perPage: 20);
      expect(live.freshness, DataFreshness.live);

      final failing = Dio();
      failing.httpClientAdapter = _StubAdapter((options) {
        throw StateError('offline');
      });
      final later = DiscoverRepository(dio: failing, cache: cache, now: () => DateTime.utc(2026, 7, 14, 7));
      final refreshed = await later.fetchTrendingRepos(force: true, page: 1, perPage: 20);

      expect(refreshed.freshness, DataFreshness.staleCache);
      expect(refreshed.data.single.fullName, 'owner/repo');
    });
  });
}
