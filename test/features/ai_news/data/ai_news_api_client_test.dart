import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/ai_hot/ai_hot_resource_cache.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/features/ai_news/data/ai_news_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockResources extends Mock implements AiHotResourceCache {}

void main() {
  late _MockResources resources;
  late AiNewsApiClient client;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    resources = _MockResources();
    client = AiNewsApiClient(resources);
  });

  test('items uses selected mode, query-specific cache request and attribution', () async {
    when(
      () => resources.getObject(
        url: ApiEndpointsConfig.aiNewsItemsPath,
        ttl: any(named: 'ttl'),
        queryParameters: any(named: 'queryParameters'),
        force: false,
      ),
    ).thenAnswer(
      (_) async => const DataResult(
        data: {
          'count': 1,
          'hasNext': false,
          'nextCursor': null,
          'items': [
            {
              'id': 'item-1',
              'title': '标题',
              'url': 'https://example.com/original',
              'permalink': 'https://aihot.virxact.com/items/item-1',
              'source': 'Source',
              'selected': true,
              'attribution': {'source': 'AI HOT', 'canonical': 'https://aihot.virxact.com/items/item-1'},
            },
          ],
        },
        freshness: DataFreshness.live,
      ),
    );

    final result = await client.fetchItems(category: 'industry', selectedOnly: true);

    expect(result.data.items.single.toDomain().attributionSource, 'AI HOT');
    final captured = verify(
      () => resources.getObject(
        url: ApiEndpointsConfig.aiNewsItemsPath,
        ttl: any(named: 'ttl'),
        queryParameters: captureAny(named: 'queryParameters'),
        force: false,
      ),
    ).captured.single as Map<String, Object?>;
    expect(captured, containsPair('mode', 'selected'));
    expect(captured, containsPair('take', 50));
    expect(captured, containsPair('category', 'industry'));
  });

  test('hot-topics maps multi-source and signal counts', () async {
    when(() => resources.getObject(url: ApiEndpointsConfig.aiHotTopicsPath, ttl: any(named: 'ttl'), force: false)).thenAnswer(
      (_) async => const DataResult(
        data: {
          'count': 1,
          'items': [
            {
              'id': 'hot-1',
              'title': 'Kimi',
              'url': 'https://example.com',
              'permalink': 'https://aihot.virxact.com/items/hot-1',
              'source': 'Source',
              'sourceCount': 16,
              'signalCount': 2,
              'sourceNames': ['A', 'B'],
              'latestAt': '2026-07-17T23:49:07Z',
            },
          ],
        },
        freshness: DataFreshness.freshCache,
      ),
    );

    final result = await client.fetchHotTopics();

    expect(result.data.single.sourceCount, 16);
    expect(result.data.single.signalCount, 2);
    expect(result.freshness, DataFreshness.freshCache);
  });

  test('daily, date detail and dailies map their public contracts', () async {
    const report = <String, Object?>{
      'date': '2026-07-18',
      'generatedAt': '2026-07-18T00:00:01Z',
      'windowStart': '2026-07-17T00:00:00Z',
      'windowEnd': '2026-07-18T00:00:00Z',
      'sections': [
        {
          'label': '行业动态',
          'items': [
            {'title': '新闻', 'summary': '摘要', 'sourceUrl': 'https://example.com', 'sourceName': 'Example'},
          ],
        },
      ],
      'flashes': <Object?>[],
    };
    when(() => resources.getObject(url: ApiEndpointsConfig.aiHotDailyPath, ttl: any(named: 'ttl'), force: false))
        .thenAnswer((_) async => const DataResult(data: report, freshness: DataFreshness.live));
    when(() => resources.getObject(url: ApiEndpointsConfig.aiHotDailyByDatePath('2026-07-18'), ttl: any(named: 'ttl'), force: false))
        .thenAnswer((_) async => const DataResult(data: report, freshness: DataFreshness.live));
    when(
      () => resources.getObject(
        url: ApiEndpointsConfig.aiHotDailiesPath,
        ttl: any(named: 'ttl'),
        queryParameters: {'take': 30},
        force: false,
      ),
    ).thenAnswer(
      (_) async => const DataResult(
        data: {
          'count': 1,
          'items': [
            {'date': '2026-07-18', 'generatedAt': '2026-07-18T00:00:01Z', 'leadTitle': '新闻'},
          ],
        },
        freshness: DataFreshness.live,
      ),
    );

    expect((await client.fetchLatestDaily()).data.itemCount, 1);
    expect((await client.fetchDaily('2026-07-18')).data.date, '2026-07-18');
    expect((await client.fetchDailies()).data.single.leadTitle, '新闻');
  });

  test('fingerprint and version map polling metadata', () async {
    when(() => resources.getObject(url: ApiEndpointsConfig.aiHotFingerprintPath, ttl: any(named: 'ttl'), force: false)).thenAnswer(
      (_) async => const DataResult(
        data: {'selected': 'f1-selected', 'all': 'f1-all'},
        freshness: DataFreshness.live,
      ),
    );
    when(() => resources.getObject(url: ApiEndpointsConfig.aiHotVersionPath, ttl: any(named: 'ttl'), force: false)).thenAnswer(
      (_) async => const DataResult(
        data: {'apiVersion': '1.4.0', 'skillVersion': '0.3.6', 'updatedAt': '2026-07-15', 'changelogUrl': 'https://aihot.virxact.com/changelog', 'recentChanges': <Object?>[]},
        freshness: DataFreshness.live,
      ),
    );

    expect((await client.fetchFingerprint()).data.selected, 'f1-selected');
    expect((await client.fetchVersion()).data.apiVersion, '1.4.0');
  });

  test('invalid daily date is rejected before requesting the network', () async {
    await expectLater(client.fetchDaily('../items'), throwsA(isA<AppException>().having((error) => error.kind, 'kind', AppExceptionKind.parse)));
    verifyNever(() => resources.getObject(url: any(named: 'url'), ttl: any(named: 'ttl'), force: any(named: 'force')));
  });
}
