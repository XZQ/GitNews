import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/ai_hot/ai_hot_api_support.dart';
import 'package:github_news/core/ai_hot/ai_hot_resource_cache.dart';
import 'package:github_news/core/domain/data_freshness.dart';
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
  late AiHotResourceCache resources;
  final now = DateTime.utc(2026, 7, 19, 10);

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    meta = CacheMetaDao(database.executor);
    cache = JsonSnapshotCacheDao(database.executor, meta);
    dio = _MockDio();
    resources = AiHotResourceCache(dio: dio, cache: cache, now: () => now);
  });

  tearDown(() => database.close());

  test('JSON 200 stores ETag and 304 reuses cached payload', () async {
    var call = 0;
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((invocation) async {
      final options = invocation.namedArguments[#options] as Options;
      expect(options.headers?['User-Agent'], AiHotApiSupport.userAgent);
      call++;
      if (call == 1) {
        expect(options.headers?['If-None-Match'], isNull);
        return _response(statusCode: 200, data: <String, Object?>{'id': 1}, etag: 'W/"items-1"');
      }
      expect(options.headers?['If-None-Match'], 'W/"items-1"');
      return _response(statusCode: 304, etag: 'W/"items-1"');
    });

    final live = await resources.getObject(url: '/api/public/items', ttl: Duration.zero);
    final cached = await resources.getObject(url: '/api/public/items', ttl: Duration.zero);

    expect(live.freshness, DataFreshness.live);
    expect(cached.freshness, DataFreshness.freshCache);
    expect(cached.data, {'id': 1});
  });

  test('RSS stores and sends both ETag and Last-Modified', () async {
    var call = 0;
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((invocation) async {
      final options = invocation.namedArguments[#options] as Options;
      call++;
      if (call == 1) {
        return _response(
          statusCode: 200,
          data: '<rss><channel /></rss>',
          etag: 'W/"feed-1"',
          lastModified: 'Sat, 18 Jul 2026 04:47:25 GMT',
        );
      }
      expect(options.headers?['If-None-Match'], 'W/"feed-1"');
      expect(options.headers?['If-Modified-Since'], 'Sat, 18 Jul 2026 04:47:25 GMT');
      return _response(statusCode: 304);
    });

    await resources.getText(url: 'https://aihot.virxact.com/feed.xml', ttl: Duration.zero);
    final result = await resources.getText(url: 'https://aihot.virxact.com/feed.xml', ttl: Duration.zero);

    expect(result.data, '<rss><channel /></rss>');
    expect(result.freshness, DataFreshness.freshCache);
  });

  test('expired remote failure returns stale cache', () async {
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
        .thenAnswer((_) async => _response(statusCode: 200, data: <String, Object?>{'id': 1}));
    await resources.getObject(url: '/api/public/items', ttl: Duration.zero);
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
        .thenThrow(DioException(type: DioExceptionType.connectionError, requestOptions: RequestOptions(path: '/api/public/items')));

    final result = await resources.getObject(url: '/api/public/items', ttl: Duration.zero);

    expect(result.data, {'id': 1});
    expect(result.freshness, DataFreshness.staleCache);
  });

  test('fresh TTL cache skips the network', () async {
    when(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
        .thenAnswer((_) async => _response(statusCode: 200, data: <String, Object?>{'id': 1}));

    await resources.getObject(url: '/api/public/version', ttl: const Duration(hours: 24));
    await resources.getObject(url: '/api/public/version', ttl: const Duration(hours: 24));

    verify(() => dio.get<Object?>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).called(1);
  });
}

Response<Object?> _response({
  required int statusCode,
  Object? data,
  String? etag,
  String? lastModified,
}) {
  return Response<Object?>(
    requestOptions: RequestOptions(path: '/resource'),
    statusCode: statusCode,
    data: data,
    headers: Headers.fromMap({
      if (etag != null) 'etag': [etag],
      if (lastModified != null) 'last-modified': [lastModified],
    }),
  );
}
