import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/trending_data_source_mode_controller.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/features/trending/data/local_trending_data_source.dart';
import 'package:github_news/features/trending/data/trending_data_source.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockTrendingRepository extends Mock implements TrendingRepository {}

class _FakeTrendingDataSource implements TrendingDataSource {
  const _FakeTrendingDataSource();

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    return const TrendingDataSnapshot(
      trendingRepos: [],
      recentRepos: [],
      languages: [],
      primaryTrend: [],
      secondaryTrend: [],
      tertiaryTrend: [],
    );
  }
}

RepoEntity _repo(
  String fullName, {
  String description = 'A useful project',
  String language = 'Dart',
}) {
  return RepoEntity(
    fullName: fullName,
    description: description,
    language: language,
    starCount: 1000,
    starDelta: 120,
    forkCount: 40,
    accentArgb: 0xFF00A389,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const TrendingQuery());
  });

  group('trendingDigestProvider', () {
    test('should expose local digest when repository returns data', () async {
      final container = await _createContainer();

      final digest = await container.read(trendingDigestProvider.future);

      expect(digest.trendingRepos, isNotEmpty);
      expect(digest.recentRepos, isNotEmpty);
      expect(digest.languages, isNotEmpty);
      expect(digest.primaryTrend, isNotEmpty);
      expect(digest.isEmpty, isFalse);
    });

    test('should propagate error when repository throws', () async {
      final repo = _MockTrendingRepository();
      when(
        () => repo.getDigest(query: any(named: 'query')),
      ).thenThrow(StateError('network down'));

      final container = ProviderContainer(
        overrides: [
          trendingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(trendingDigestProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test('should expose empty digest when repository returns no data',
        () async {
      final repo = _MockTrendingRepository();
      when(
        () => repo.getDigest(query: any(named: 'query')),
      ).thenAnswer(
        (_) async => const TrendingDigest(
          trendingRepos: [],
          recentRepos: [],
          languages: [],
          primaryTrend: [],
          secondaryTrend: [],
          tertiaryTrend: [],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          trendingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(trendingDigestProvider.future);

      expect(digest.isEmpty, isTrue);
      expect(digest.allRepos, isEmpty);
    });

    test('should pass filter state into repository query', () async {
      final repo = _MockTrendingRepository();
      TrendingQuery? capturedQuery;
      when(
        () => repo.getDigest(query: any(named: 'query')),
      ).thenAnswer((invocation) async {
        capturedQuery = invocation.namedArguments[#query] as TrendingQuery;
        return const TrendingDigest(
          trendingRepos: [],
          recentRepos: [],
          languages: [],
          primaryTrend: [],
          secondaryTrend: [],
          tertiaryTrend: [],
        );
      });

      final container = ProviderContainer(
        overrides: [
          trendingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.read(trendingWindowFilterProvider.notifier).state = 'week';
      container.read(trendingLanguageFilterProvider.notifier).state = 'rust';
      container.read(trendingBoardFilterProvider.notifier).state = 'mcp';
      await container.read(trendingDigestProvider.future);

      expect(capturedQuery?.window, TrendingWindow.week);
      expect(capturedQuery?.language, 'rust');
      expect(capturedQuery?.board, TrendingBoard.mcp);
    });
  });

  group('trending filter providers', () {
    test('should default window board and language filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trendingWindowFilterProvider), 'today');
      expect(container.read(trendingBoardFilterProvider), 'all');
      expect(container.read(trendingLanguageFilterProvider), 'all');
    });

    test('should reflect updated filter state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(trendingWindowFilterProvider.notifier).state = 'week';
      container.read(trendingBoardFilterProvider.notifier).state = 'agent';
      container.read(trendingLanguageFilterProvider.notifier).state = 'rust';

      expect(container.read(trendingWindowFilterProvider), 'week');
      expect(container.read(trendingBoardFilterProvider), 'agent');
      expect(container.read(trendingLanguageFilterProvider), 'rust');
    });

    test('filterTrendingRepos should match repo name description and language',
        () {
      final repos = [
        _repo(
          'openai/codex',
          description: 'AI coding agent',
          language: 'TypeScript',
        ),
        _repo(
          'modelcontextprotocol/servers',
          description: 'MCP reference servers',
          language: 'Python',
        ),
      ];

      expect(filterTrendingRepos(repos, '').length, 2);
      expect(filterTrendingRepos(repos, 'codex'), [repos.first]);
      expect(filterTrendingRepos(repos, 'mcp'), [repos.last]);
      expect(filterTrendingRepos(repos, 'python'), [repos.last]);
      expect(filterTrendingRepos(repos, 'missing'), isEmpty);
    });

    test('filteredTrendingDigestProvider should filter current digest locally',
        () async {
      final repo = _MockTrendingRepository();
      when(
        () => repo.getDigest(query: any(named: 'query')),
      ).thenAnswer(
        (_) async => TrendingDigest(
          trendingRepos: [
            _repo('openai/codex', language: 'TypeScript'),
            _repo('google/gemini-cli', language: 'Go'),
          ],
          recentRepos: [
            _repo('modelcontextprotocol/servers', language: 'Python'),
          ],
          languages: const [],
          primaryTrend: const [],
          secondaryTrend: const [],
          tertiaryTrend: const [],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          trendingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.read(trendingSearchQueryProvider.notifier).state = 'python';
      final digest = await container.read(
        filteredTrendingDigestProvider.future,
      );

      expect(digest.trendingRepos, isEmpty);
      expect(
        digest.recentRepos.single.fullName,
        'modelcontextprotocol/servers',
      );
      verify(() => repo.getDigest(query: any(named: 'query'))).called(1);
    });
  });

  group('trending data source mode', () {
    test('should default to local data source', () async {
      final container = await _createContainer();

      expect(
        container.read(trendingDataSourceModeControllerProvider),
        TrendingDataSourceMode.local,
      );
      expect(
        container.read(trendingDataSourceProvider),
        isA<LocalTrendingDataSource>(),
      );
    });

    test('should use GitHub data source when persisted mode is github',
        () async {
      const fake = _FakeTrendingDataSource();
      final container = await _createContainer(
        prefs: {'trending_data_source_mode': 'github'},
        overrides: [
          githubTrendingDataSourceProvider.overrideWithValue(fake),
        ],
      );

      expect(
        container.read(trendingDataSourceModeControllerProvider),
        TrendingDataSourceMode.github,
      );
      expect(
        identical(container.read(trendingDataSourceProvider), fake),
        isTrue,
      );
    });

    test('should persist selected mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(trendingDataSourceModeControllerProvider.notifier)
          .setMode(TrendingDataSourceMode.github);

      expect(prefs.getString('trending_data_source_mode'), 'github');
    });

    test('status should describe local mode', () async {
      final container = await _createContainer();

      final status = container.read(trendingDataSourceStatusProvider);

      expect(status.isGithub, isFalse);
      expect(status.label, '本地数据');
    });

    test('status should describe anonymous GitHub mode', () async {
      final container = await _createContainer(
        prefs: {'trending_data_source_mode': 'github'},
      );

      final status = container.read(trendingDataSourceStatusProvider);

      expect(status.isGithub, isTrue);
      expect(status.hasToken, isFalse);
      expect(status.label, 'GitHub 匿名 · 缓存5分钟');
    });

    test('status should describe token GitHub mode', () async {
      final container = await _createContainer(
        prefs: {
          'trending_data_source_mode': 'github',
          'github_personal_access_token': 'github_pat_test',
        },
      );

      final status = container.read(trendingDataSourceStatusProvider);

      expect(status.isGithub, isTrue);
      expect(status.hasToken, isTrue);
      expect(status.label, 'GitHub Token · 缓存5分钟');
    });
  });

  group('LocalTrendingDataSource', () {
    test('should filter repos by language when query has language', () async {
      const dataSource = LocalTrendingDataSource();

      final snapshot = await dataSource.fetchTrending(
        const TrendingQuery(language: 'Rust'),
      );

      expect(snapshot.trendingRepos, isNotEmpty);
      expect(
        snapshot.trendingRepos.every((repo) => repo.language == 'Rust'),
        isTrue,
      );
    });

    test('should keep all repos when language is all', () async {
      const dataSource = LocalTrendingDataSource();

      final snapshot = await dataSource.fetchTrending(const TrendingQuery());

      expect(snapshot.trendingRepos.length, greaterThan(3));
      expect(snapshot.recentRepos, isNotEmpty);
    });

    test('should filter repos by board type', () async {
      const dataSource = LocalTrendingDataSource();

      final snapshot = await dataSource.fetchTrending(
        const TrendingQuery(board: TrendingBoard.mcp),
      );

      expect(snapshot.trendingRepos, isNotEmpty);
      expect(
        snapshot.trendingRepos.every(
          (repo) =>
              '${repo.fullName} ${repo.description}'.toLowerCase().contains(
                    'mcp',
                  ),
        ),
        isTrue,
      );
    });
  });
}

Future<ProviderContainer> _createContainer({
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}
