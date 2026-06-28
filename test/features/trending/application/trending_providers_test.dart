import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrendingRepository extends Mock implements TrendingRepository {}

void main() {
  group('trendingDigestProvider', () {
    test('should expose local digest when repository returns data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final digest = await container.read(trendingDigestProvider.future);

      expect(digest.trendingRepos, isNotEmpty);
      expect(digest.recentRepos, isNotEmpty);
      expect(digest.languages, isNotEmpty);
      expect(digest.primaryTrend, isNotEmpty);
      expect(digest.isEmpty, isFalse);
    });

    test('should propagate error when repository throws', () async {
      final repo = _MockTrendingRepository();
      when(repo.getDigest).thenThrow(StateError('network down'));

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
      when(repo.getDigest).thenAnswer(
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
  });

  group('trending filter providers', () {
    test('should default window to today and language to all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trendingWindowFilterProvider), 'today');
      expect(container.read(trendingLanguageFilterProvider), 'all');
    });

    test('should reflect updated filter state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(trendingWindowFilterProvider.notifier).state = 'week';
      container.read(trendingLanguageFilterProvider.notifier).state = 'rust';

      expect(container.read(trendingWindowFilterProvider), 'week');
      expect(container.read(trendingLanguageFilterProvider), 'rust');
    });
  });
}
