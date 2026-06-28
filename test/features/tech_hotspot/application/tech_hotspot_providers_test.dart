import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTechHotspotRepository extends Mock
    implements TechHotspotRepository {}

void main() {
  group('techHotspotDigestProvider', () {
    test('should expose local digest when repository returns data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final digest = container.read(techHotspotDigestProvider);

      expect(digest.languages, isNotEmpty);
      expect(digest.topics, isNotEmpty);
      expect(digest.heatTrend, isNotEmpty);
      expect(digest.hotTags, isNotEmpty);
      expect(digest.topics.every((topic) => topic.heat >= 0), isTrue);
    });

    test('should propagate error when repository throws', () {
      final repo = _MockTechHotspotRepository();
      when(repo.getDigest).thenThrow(StateError('disk read failed'));

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(techHotspotDigestProvider),
        throwsA(isA<StateError>()),
      );
    });

    test('should expose empty digest when repository returns no data', () {
      final repo = _MockTechHotspotRepository();
      const empty = TechHotspotDigest(
        languages: [],
        topics: [],
        heatTrend: [],
        hotTags: [],
      );
      when(repo.getDigest).thenReturn(empty);
      when(repo.allTopics).thenReturn(const []);
      when(() => repo.getById(any())).thenReturn(null);

      final container = ProviderContainer(
        overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final digest = container.read(techHotspotDigestProvider);

      expect(digest.languages, isEmpty);
      expect(digest.topics, isEmpty);
      expect(digest.heatTrend, isEmpty);
      expect(digest.hotTags, isEmpty);
    });
  });

  group('repository contract', () {
    test('getById returns null for unknown id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(techHotspotRepositoryProvider);
      expect(repo.getById('non-existent-id'), isNull);
    });

    test('getById returns matching topic for known id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(techHotspotRepositoryProvider);
      final first = repo.allTopics().first;
      expect(repo.getById(first.id)?.id, first.id);
    });

    test('allTopics matches digest.topics', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final digest = container.read(techHotspotDigestProvider);
      final repo = container.read(techHotspotRepositoryProvider);
      expect(repo.allTopics().length, digest.topics.length);
    });
  });
}
