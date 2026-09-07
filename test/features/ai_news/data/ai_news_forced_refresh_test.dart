import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/ai_hot/ai_hot_resource_cache.dart';
import 'package:github_news/core/config/ai_news_sources_config.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/ai_news/data/aggregated_ai_news_repository.dart';
import 'package:github_news/features/ai_news/data/ai_news_api_client.dart';
import 'package:github_news/features/ai_news/data/ai_news_rss_client.dart';
import 'package:github_news/features/ai_news/data/remote_ai_news_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() => registerFallbackValue(Options()));
  test('forced aggregate refresh revalidates both REST and RSS inside their TTL', () async {
    final db = await LocalDatabase.openInMemory();
    addTearDown(db.close);
    final dio = _MockDio();
    final now = DateTime.utc(2026, 7, 19);
    final resources = AiHotResourceCache(dio: dio, cache: JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor)), now: () => now);
    const source = AiNewsSourceConfig(id: 'test', name: 'Test', feedUrl: 'https://example.com/feed.xml', categoryCode: 'industry');
    final repository = AggregatedAiNewsRepository(RemoteAiNewsRepository(AiNewsApiClient(resources)), AiNewsRssClient(resources), sources: const [source], clock: () => now);
    final calls = <String, int>{};
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      final count = calls.update(url, (value) => value + 1, ifAbsent: () => 1);
      final headers = (invocation.namedArguments[#options] as Options).headers;
      if (count > 1) expect(headers?['If-None-Match'], 'test-etag');
      return Response<Object?>(
        requestOptions: RequestOptions(path: url),
        statusCode: count == 1 ? 200 : 304,
        headers: Headers.fromMap({
          'etag': ['test-etag'],
        }),
        data: count > 1
            ? null
            : url == source.feedUrl
            ? '<rss><channel><item><guid>rss</guid><title>RSS release</title><link>https://example.com/rss</link></item></channel></rss>'
            : {
                'count': 1,
                'hasNext': false,
                'items': [
                  {'id': 'rest', 'title': 'REST release', 'url': 'https://example.com/rest', 'selected': true},
                ],
              },
      );
    });
    expect((await repository.fetchItems()).data.items, hasLength(2));
    expect((await repository.fetchItems()).freshness, DataFreshness.freshCache);
    expect(calls, {ApiEndpointsConfig.aiNewsItemsPath: 1, source.feedUrl: 1});
    final refreshed = await repository.fetchItems(force: true);
    expect(refreshed.data.items, hasLength(2));
    expect(calls, {ApiEndpointsConfig.aiNewsItemsPath: 2, source.feedUrl: 2});
  });
}
