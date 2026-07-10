import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/core/github/github_resource_cache.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late LocalDatabase database;
  late CacheMetaDao meta;
  late JsonSnapshotCacheDao cache;
  late _MockDio dio;
  late GitHubResourceCache resources;
  final now = DateTime.utc(2026, 7, 10, 10);

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    meta = CacheMetaDao(database.executor);
    cache = JsonSnapshotCacheDao(database.executor, meta);
    dio = _MockDio();
    resources = GitHubResourceCache(
      dio: dio,
      cache: cache,
      now: () => now,
    );
  });

  tearDown(() => database.close());

  test('200 stores payload and ETag, then 304 reuses fresh cache', () async {
    var call = 0;
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final options = invocation.namedArguments[#options] as Options;
      call++;
      if (call == 1) {
        expect(options.headers?['If-None-Match'], isNull);
        return _response(
          statusCode: 200,
          data: <String, Object?>{'id': 1},
          etag: 'W/"repo-1"',
        );
      }
      expect(options.headers?['If-None-Match'], 'W/"repo-1"');
      return _response(statusCode: 304);
    });

    final live = await resources.getObject(url: '/repos/openai/codex');
    final cached = await resources.getObject(url: '/repos/openai/codex');

    expect(live.freshness, DataFreshness.live);
    expect(cached.freshness, DataFreshness.freshCache);
    expect(cached.data, {'id': 1});
    expect(call, 2);
  });

  test('304 without a cached payload throws a cache error', () async {
    final key = GitHubResourceCache.cacheKey(
      scope: 'anonymous',
      method: 'GET',
      url: '/repos/openai/codex',
    );
    await meta.writeEtag(key, 'W/"orphan"');
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => _response(statusCode: 304));

    expect(
      () => resources.getObject(url: '/repos/openai/codex'),
      throwsA(
        isA<AppException>().having(
          (error) => error.kind,
          'kind',
          AppExceptionKind.cache,
        ),
      ),
    );
  });

  test('malformed cached payload is deleted and request omits ETag', () async {
    final key = GitHubResourceCache.cacheKey(
      scope: 'anonymous',
      method: 'GET',
      url: '/repos/openai/codex',
    );
    await cache.upsertWithEtag(
      key: key,
      payload: const {'kind': 'list', 'data': []},
      etag: 'W/"wrong-kind"',
      now: now,
    );
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final options = invocation.namedArguments[#options] as Options;
      expect(options.headers?['If-None-Match'], isNull);
      return _response(
        statusCode: 200,
        data: <String, Object?>{'id': 2},
        etag: 'W/"repo-2"',
      );
    });

    final result = await resources.getObject(url: '/repos/openai/codex');

    expect(result.data, {'id': 2});
    expect(result.freshness, DataFreshness.live);
  });

  test('list resources use a token-scoped URL and preserve list payloads', () async {
    final scoped = GitHubResourceCache(
      dio: dio,
      cache: cache,
      cacheScope: 'token_abcd',
      token: 'secret',
      now: () => now,
    );
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => _response(
        statusCode: 200,
        data: <Object?>[
          <String, Object?>{'login': 'octocat'},
        ],
      ),
    );

    final result = await scoped.getList(
      url: '/repos/openai/codex/contributors',
      queryParameters: const {'per_page': 12},
    );

    expect(result.data.single, {'login': 'octocat'});
    final key = GitHubResourceCache.cacheKey(
      scope: 'token_abcd',
      method: 'GET',
      url: '/repos/openai/codex/contributors',
      queryParameters: const {'per_page': 12},
    );
    expect(await cache.read(key), isNotNull);
    expect(key, isNot(contains('secret')));
  });
}

Response<Object?> _response({
  required int statusCode,
  Object? data,
  String? etag,
}) {
  return Response<Object?>(
    requestOptions: RequestOptions(path: '/resource'),
    statusCode: statusCode,
    data: data,
    headers: Headers.fromMap({
      if (etag != null) 'etag': [etag],
    }),
  );
}
