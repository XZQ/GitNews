import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/project/application/project_providers.dart';
import 'package:github_news/features/project/data/local_project_repository.dart';
import 'package:github_news/features/project/domain/project_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockProjectRepository extends Mock implements ProjectRepository {}

RepoEntity _repo(
  String fullName, {
  String description = 'AI developer tool',
  String language = 'Dart',
}) {
  return RepoEntity(
    fullName: fullName,
    description: description,
    language: language,
    starCount: 1200,
    starDelta: 80,
    forkCount: 30,
    accentArgb: 0xFF00A389,
  );
}

ContributorEntity _contributor(String login, {int contributions = 42}) {
  return ContributorEntity(
    login: login,
    contributions: contributions,
    avatarAccentArgb: 0xFF6366F1,
  );
}

void main() {
  group('project search', () {
    test('filterProjectRepos should match repo name description and language', () {
      final repos = [
        _repo('openai/codex', language: 'TypeScript'),
        _repo(
          'modelcontextprotocol/servers',
          description: 'MCP server collection',
          language: 'Python',
        ),
      ];

      expect(filterProjectRepos(repos, '').length, 2);
      expect(filterProjectRepos(repos, 'codex'), [repos.first]);
      expect(filterProjectRepos(repos, 'mcp'), [repos.last]);
      expect(filterProjectRepos(repos, 'python'), [repos.last]);
      expect(filterProjectRepos(repos, 'missing'), isEmpty);
    });

    test('filterProjectContributors should match login and contributions', () {
      final contributors = [
        _contributor('gaearon', contributions: 128),
        _contributor('sindresorhus', contributions: 64),
      ];

      expect(filterProjectContributors(contributors, '').length, 2);
      expect(filterProjectContributors(contributors, 'gaearon'), [
        contributors.first,
      ]);
      expect(filterProjectContributors(contributors, '64'), [
        contributors.last,
      ]);
      expect(filterProjectContributors(contributors, 'missing'), isEmpty);
    });

    test('filteredProjectDigestProvider should filter current digest', () async {
      final repo = _MockProjectRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => ProjectDigest(
          repos: [
            _repo('openai/codex', language: 'TypeScript'),
            _repo('vercel/next.js', language: 'JavaScript'),
          ],
          contributors: [
            _contributor('codex-maintainer'),
            _contributor('frontend-dev'),
          ],
          primaryTrend: const [],
          secondaryTrend: const [],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.read(projectSearchQueryProvider.notifier).state = 'codex';
      final digest = await container.read(filteredProjectDigestProvider.future);

      expect(digest.repos.single.fullName, 'openai/codex');
      expect(digest.contributors.single.login, 'codex-maintainer');
      verify(repo.getDigest).called(1);
    });
  });
}
