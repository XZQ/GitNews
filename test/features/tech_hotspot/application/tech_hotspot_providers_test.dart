import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/data/local_tech_hotspot_repository.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTechHotspotRepository extends Mock
    implements TechHotspotRepository {}

const _sampleDigest = TechHotspotDigest(
  languages: [],
  topics: [
    TechTopic(
      id: 'agent-runtime',
      name: 'Agent 框架',
      category: 'Agent',
      heat: 92,
      growth: 12.4,
      mentions: 230,
      relatedRepos: 42,
      summary: 'LangGraph、AutoGen、CrewAI 等长任务 Agent 框架升温',
    ),
    TechTopic(
      id: 'local-inference',
      name: '本地推理',
      category: 'Model',
      heat: 84,
      growth: 8.1,
      mentions: 160,
      relatedRepos: 28,
      summary: 'Ollama 与端侧模型部署继续增长',
    ),
  ],
  heatTrend: [],
  hotTags: ['agent', 'mcp', 'local-llm'],
);

void main() {
  group('techHotspotDigestProvider', () {
    test('should expose local digest when repository returns data', () async {
      final container = ProviderContainer(
        overrides: [
          techHotspotRepositoryProvider.overrideWithValue(
            const LocalTechHotspotRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(techHotspotDigestProvider.future);

      expect(digest.languages, isNotEmpty);
      expect(digest.topics, isNotEmpty);
      expect(digest.heatTrend, isNotEmpty);
      expect(digest.hotTags, isNotEmpty);
      expect(digest.topics.every((topic) => topic.heat >= 0), isTrue);
    });

    test('should propagate error when repository throws', () async {
      final repo = _MockTechHotspotRepository();
      when(repo.getDigest).thenThrow(StateError('disk read failed'));

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(techHotspotDigestProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test('should expose empty digest when repository returns no data',
        () async {
      final repo = _MockTechHotspotRepository();
      const empty = TechHotspotDigest(
        languages: [],
        topics: [],
        heatTrend: [],
        hotTags: [],
      );
      when(repo.getDigest).thenAnswer((_) async => empty);
      when(repo.allTopics).thenAnswer((_) async => const []);
      when(() => repo.getById(any())).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final digest = await container.read(techHotspotDigestProvider.future);

      expect(digest.languages, isEmpty);
      expect(digest.topics, isEmpty);
      expect(digest.heatTrend, isEmpty);
      expect(digest.hotTags, isEmpty);
    });
  });

  group('repository contract', () {
    test('getById returns null for unknown id', () async {
      final container = ProviderContainer(
        overrides: [
          techHotspotRepositoryProvider.overrideWithValue(
            const LocalTechHotspotRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(techHotspotRepositoryProvider);
      expect(await repo.getById('non-existent-id'), isNull);
    });

    test('getById returns matching topic for known id', () async {
      final container = ProviderContainer(
        overrides: [
          techHotspotRepositoryProvider.overrideWithValue(
            const LocalTechHotspotRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(techHotspotRepositoryProvider);
      final first = (await repo.allTopics()).first;
      final found = await repo.getById(first.id);
      expect(found?.id, first.id);
    });

    test('allTopics matches digest.topics', () async {
      final container = ProviderContainer(
        overrides: [
          techHotspotRepositoryProvider.overrideWithValue(
            const LocalTechHotspotRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(techHotspotDigestProvider.future);
      final repo = container.read(techHotspotRepositoryProvider);
      expect((await repo.allTopics()).length, digest.topics.length);
    });
  });

  group('tech hotspot search', () {
    test('filterTechTopics should match topic name category summary and id',
        () {
      expect(filterTechTopics(_sampleDigest.topics, '').length, 2);
      expect(
        filterTechTopics(_sampleDigest.topics, 'agent').single.id,
        'agent-runtime',
      );
      expect(
        filterTechTopics(_sampleDigest.topics, 'ollama').single.id,
        'local-inference',
      );
      expect(
        filterTechTopics(_sampleDigest.topics, 'model').single.id,
        'local-inference',
      );
      expect(filterTechTopics(_sampleDigest.topics, 'missing'), isEmpty);
    });

    test('filteredTechHotspotDigestProvider should filter current digest',
        () async {
      final repo = _MockTechHotspotRepository();
      when(repo.getDigest).thenAnswer((_) async => _sampleDigest);

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(techHotspotSearchQueryProvider.notifier).state = 'mcp';
      final digest = await container.read(
        filteredTechHotspotDigestProvider.future,
      );

      expect(digest.topics, isEmpty);
      expect(digest.hotTags, ['mcp']);
      verify(repo.getDigest).called(1);
    });

    test('filteredTechHotspotDigestProvider should apply category filter',
        () async {
      final repo = _MockTechHotspotRepository();
      when(repo.getDigest).thenAnswer((_) async => _sampleDigest);

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(techHotspotCategoryFilterProvider.notifier).state =
          'Agent';
      final digest = await container.read(
        filteredTechHotspotDigestProvider.future,
      );

      expect(digest.topics.single.id, 'agent-runtime');
      expect(digest.hotTags, _sampleDigest.hotTags);
    });
  });
}
