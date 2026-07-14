import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

  DiscoverRepository buildRepo(Dio dio) => DiscoverRepository(
        dio: dio,
        cache: cache,
        now: () => DateTime.utc(2026, 7, 14),
      );

  group('fetchProfiles 分页', () {
    test('page=1 返回白名单(enriched) + 搜索结果(占位)', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {
                'login': 'some-new-org',
                'avatar_url': 'https://github.com/some-new-org.png',
                'html_url': 'https://github.com/some-new-org',
                'type': 'Organization',
              },
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

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 1,
        perPage: 20,
      );

      final whitelistCount = DiscoverQueries.officialLogins.length;
      expect(result.data.length, whitelistCount + 1);
      final whitelist = result.data.take(whitelistCount).toList();
      expect(whitelist.every((p) => p.enriched), isTrue);
      final searchHit = result.data.last;
      expect(searchHit.login, 'some-new-org');
      expect(searchHit.enriched, isFalse);
    });

    test('page=2 只返回搜索结果,不含白名单', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'items': [
            {
              'login': 'page2-org',
              'avatar_url': '',
              'html_url': '',
              'type': 'Organization',
            },
          ],
        };
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 2,
        perPage: 20,
      );

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
        return {
          'login': options.path.split('/').last,
          'name': 'OpenAI',
          'type': 'Organization',
          'bio': 'bio',
          'public_repos': 100,
          'followers': 200,
          'avatar_url': '',
          'html_url': '',
        };
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 1,
        perPage: 20,
      );

      final openaiEntries = result.data.where((p) => p.login == 'openai');
      expect(openaiEntries.length, 1);
      expect(openaiEntries.single.enriched, isTrue);
    });
  });

  group('fetchProfileDetail', () {
    test('透传 login/kind 给 profile client,返回 enriched 实体', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'login': 'karpathy',
          'name': 'Andrej Karpathy',
          'type': 'User',
          'bio': 'researcher',
          'public_repos': 60,
          'followers': 200000,
          'avatar_url': '',
          'html_url': '',
        };
      });
      final repo = buildRepo(dio);

      final result = await repo.fetchProfileDetail(
        login: 'karpathy',
        kind: DiscoverProfileKind.people,
      );

      expect(result.data.login, 'karpathy');
      expect(result.data.enriched, isTrue);
      expect(result.data.followers, 200000);
    });
  });
}
