import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/repo_snapshot_history_dao.dart';
import 'package:github_news/features/trending/data/github_trending_data_source.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late LocalDatabase db;
  late RepoSnapshotHistoryDao snapshotHistory;
  late _MockDio dio;
  late GithubTrendingDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    snapshotHistory = RepoSnapshotHistoryDao(JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor)));
    dio = _MockDio();
    dataSource = GithubTrendingDataSource(
        dio: dio,
        now: () => DateTime.utc(
              2026,
              7,
              4,
              12,
            ),
        snapshotHistory: snapshotHistory);
  });

  tearDown(() async {
    await db.close();
  });

  group('GithubTrendingDataSource.fetchTrending', () {
    test('should call GitHub search with query qualifiers', () async {
      Map<String, Object?>? capturedQuery;
      Options? capturedOptions;
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedQuery = invocation.namedArguments[#queryParameters] as Map<String, Object?>;
        capturedOptions = invocation.namedArguments[#options] as Options;
        return _okResponse(_searchBody());
      });

      await dataSource.fetchTrending(const TrendingQuery(window: TrendingWindow.week, language: 'Rust'));

      expect(capturedQuery?['q'], contains('stars:>50'));
      expect(capturedQuery?['q'], contains('pushed:>=2026-06-27'));
      expect(capturedQuery?['q'], contains('archived:false'));
      expect(capturedQuery?['q'], contains('language:Rust'));
      expect(capturedQuery?['sort'], 'stars');
      expect(capturedQuery?['order'], 'desc');
      expect(capturedQuery?['per_page'], 20);
      expect(capturedOptions?.headers?['Authorization'], isNull);
    });

    test('should add board keywords to GitHub search query', () async {
      Map<String, Object?>? capturedQuery;
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedQuery = invocation.namedArguments[#queryParameters] as Map<String, Object?>;
        return _okResponse(_searchBody());
      });

      await dataSource.fetchTrending(const TrendingQuery(board: TrendingBoard.mcp));

      expect(capturedQuery?['q'], contains('mcp'));
      expect(capturedQuery?['q'], contains('in:name,description,readme'));
    });

    test('should use created qualifier for new repos board', () async {
      Map<String, Object?>? capturedQuery;
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedQuery = invocation.namedArguments[#queryParameters] as Map<String, Object?>;
        return _okResponse(_searchBody());
      });

      await dataSource.fetchTrending(const TrendingQuery(window: TrendingWindow.today, board: TrendingBoard.newRepos));

      expect(capturedQuery?['q'], contains('created:>=2026-07-03'));
      expect(capturedQuery?['q'], isNot(contains('pushed:>=')));
    });

    test('should send bearer token when token is configured', () async {
      Options? capturedOptions;
      dataSource = GithubTrendingDataSource(
        dio: dio,
        token: 'github_pat_test',
        now: () => DateTime.utc(2026, 7, 4, 12),
        snapshotHistory: snapshotHistory,
      );
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((invocation) async {
        capturedOptions = invocation.namedArguments[#options] as Options;
        return _okResponse(_searchBody());
      });

      await dataSource.fetchTrending(const TrendingQuery());

      expect(capturedOptions?.headers?['Authorization'], 'Bearer github_pat_test');
    });

    test('should map GitHub search response to trending snapshot', () async {
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _okResponse(_searchBody()));

      final snapshot = await dataSource.fetchTrending(const TrendingQuery(language: 'Python'));

      expect(snapshot.trendingRepos, hasLength(2));
      expect(snapshot.trendingRepos.first.fullName, 'openai/codex');
      expect(snapshot.trendingRepos.first.language, 'Python');
      expect(snapshot.trendingRepos.first.starCount, 12000);
      expect(snapshot.trendingRepos.first.starDelta, greaterThan(0));
      expect(snapshot.languages.first.name, 'Python');
      expect(snapshot.primaryTrend, hasLength(7));
    });

    test('should prefer observed local snapshot history for repo trend', () async {
      await snapshotHistory.record(
        fullName: 'openai/codex',
        stars: 11900,
        forks: 790,
        capturedAt: DateTime.utc(2026, 6, 29, 8),
      );
      when(() => dio.get<Map<String, Object?>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _okResponse(_searchBody()));

      final snapshot = await dataSource.fetchTrending(const TrendingQuery(window: TrendingWindow.week));

      final repo = snapshot.trendingRepos.first;
      expect(repo.starDelta, 100);
      expect(repo.trend, [11900, 12000]);
      expect(repo.trendBasis, MetricBasis.observed);
      expect(snapshot.primaryTrend, [11900, 12000]);
    });

    test('should throw parse AppException when items field is missing', () async {
      when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
          .thenAnswer((_) async => _okResponse(<String, Object?>{'total_count': 1}));

      await expectLater(dataSource.fetchTrending(const TrendingQuery()), throwsA(predicate<AppException>((e) => e.kind == AppExceptionKind.parse)));
    });

    test('should map GitHub search rate limit to rateLimit AppException', () async {
      when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options'))).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: ApiEndpointsConfig.githubSearchRepositoriesPath),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ApiEndpointsConfig.githubSearchRepositoriesPath),
            statusCode: 403,
            headers: Headers.fromMap({
              'x-ratelimit-remaining': ['0'],
              'x-ratelimit-reset': ['1783168200']
            }),
          ),
        ),
      );

      await expectLater(dataSource.fetchTrending(const TrendingQuery()), throwsA(predicate<AppException>((e) => e.kind == AppExceptionKind.rateLimit && e.retryAfterSeconds != null)));
    });
  });
}

Response<Map<String, Object?>> _okResponse(Map<String, Object?> body) {
  return Response<Map<String, Object?>>(requestOptions: RequestOptions(path: ApiEndpointsConfig.githubSearchRepositoriesPath), statusCode: 200, data: body);
}

Map<String, Object?> _searchBody() {
  return <String, Object?>{
    'total_count': 2,
    'items': <Object?>[
      <String, Object?>{'full_name': 'openai/codex', 'description': 'Coding agent', 'language': 'Python', 'stargazers_count': 12000, 'forks_count': 800, 'score': 24.5},
      <String, Object?>{'full_name': 'modelcontextprotocol/servers', 'description': null, 'language': 'Python', 'stargazers_count': 6400, 'forks_count': 520, 'score': 18.2}
    ]
  };
}
