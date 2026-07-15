import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/tech_hotspot/data/github_tech_hotspot_queries.dart';
import 'package:github_news/features/tech_hotspot/data/github_tech_hotspot_repository.dart';
import 'package:github_news/features/tech_hotspot/data/tech_hotspot_history_dao.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late LocalDatabase db;
  late JsonSnapshotCacheDao cache;
  late TechHotspotHistoryDao history;
  late _MockDio dio;
  late GithubTechHotspotRepository repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    cache = JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor));
    history = TechHotspotHistoryDao(cache);
    dio = _MockDio();
    repository = GithubTechHotspotRepository(
      dio: dio,
      cache: cache,
      history: history,
      now: () => DateTime.utc(2026, 7, 4, 12),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('should prefer observed local topic history for growth and heat trend', () async {
    await history.record(
      id: techHotspotTopicQueries.first.id,
      heat: 40,
      mentions: 80,
      relatedRepos: 100,
      capturedAt: DateTime.utc(2026, 7, 3, 8),
    );
    var index = 0;
    when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenAnswer((_) async {
      final query = techHotspotTopicQueries[index++];
      return _okResponse(_searchBody(query.id, total: query == techHotspotTopicQueries.first ? 130 : 80));
    });

    final result = await repository.getDigest();
    final digest = result.data;
    final firstTopic = digest.topics.first;

    expect(firstTopic.growth, 30);
    expect(firstTopic.growthBasis, MetricBasis.observed);
    expect(result.freshness, DataFreshness.live);
    expect(digest.heatTrend.map((point) => point.value).toList(), [40, firstTopic.heat]);
  });
}

Response<Map<String, Object?>> _okResponse(Map<String, Object?> body) {
  return Response<Map<String, Object?>>(requestOptions: RequestOptions(path: ApiEndpointsConfig.githubSearchRepositoriesPath), statusCode: 200, data: body);
}

Map<String, Object?> _searchBody(String id, {required int total}) {
  return <String, Object?>{
    'total_count': total,
    'items': <Object?>[
      <String, Object?>{'full_name': 'example/$id', 'description': 'AI repository', 'language': 'Python', 'stargazers_count': 24000, 'forks_count': 1200, 'score': 20.0}
    ]
  };
}
