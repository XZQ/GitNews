import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/demo_data.dart';
import 'package:github_news/core/demo_data_mappers.dart';
import 'package:github_news/features/repo_detail/application/repo_detail_providers.dart';
import 'package:github_news/features/repo_detail/domain/repo_detail_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepoDetailRepository extends Mock implements RepoDetailRepository {}

void main() {
  group('repoDetailDigestProvider', () {
    test('should expose local digest for known repo', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final digest = await container.read(
        repoDetailDigestProvider('denoland/deno').future,
      );

      expect(digest.repo.fullName, 'denoland/deno');
      expect(digest.contributors, isNotEmpty);
      expect(digest.relatedRepos, isNotEmpty);
      expect(digest.primaryTrend, isNotEmpty);
      expect(digest.compareTrend, isNotEmpty);
    });

    test('should propagate error when repository throws on unknown repo',
        () async {
      final repo = _MockRepoDetailRepository();
      when(() => repo.getDetail(any())).thenThrow(StateError('not found'));

      final container = ProviderContainer(
        overrides: [
          repoDetailRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(repoDetailDigestProvider('foo/bar').future),
        throwsA(isA<StateError>()),
      );
    });

    test('family should return distinct digests per argument', () async {
      final repo = _MockRepoDetailRepository();
      final repoA = DemoData.trending.first.toEntity();
      final repoB = DemoData.trending.elementAt(1).toEntity();

      when(() => repo.getDetail(repoA.fullName)).thenAnswer(
        (_) async => RepoDetailDigest(
          repo: repoA,
          contributors: const [],
          relatedRepos: const [],
          primaryTrend: const [1.0],
          compareTrend: const [0.5],
        ),
      );
      when(() => repo.getDetail(repoB.fullName)).thenAnswer(
        (_) async => RepoDetailDigest(
          repo: repoB,
          contributors: const [],
          relatedRepos: const [],
          primaryTrend: const [2.0],
          compareTrend: const [1.0],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          repoDetailRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final a = await container.read(
        repoDetailDigestProvider(repoA.fullName).future,
      );
      final b = await container.read(
        repoDetailDigestProvider(repoB.fullName).future,
      );

      expect(a.repo.fullName, repoA.fullName);
      expect(b.repo.fullName, repoB.fullName);
      expect(a.primaryTrend.first, 1.0);
      expect(b.primaryTrend.first, 2.0);
    });
  });
}
