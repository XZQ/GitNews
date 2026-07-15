import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_activity_event.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/repo_detail/data/github_repo_detail_cache_codec.dart';
import 'package:github_news/features/repo_detail/domain/repo_detail_repository.dart';

void main() {
  test('repo detail cache round-trips real activities', () {
    final digest = RepoDetailDigest(
      repo: _repo,
      contributors: const [],
      relatedRepos: const [],
      primaryTrend: const [1],
      compareTrend: const [0.5],
      activities: [
        RepoActivityEvent(
          repoFullName: _repo.fullName,
          type: RepoActivityType.release,
          title: 'published: v1.3.0',
          actorLogin: 'octocat',
          occurredAt: DateTime.utc(2026, 7, 11, 10),
          htmlUrl: 'https://github.com/owner/repo/releases/v1.3.0',
          basis: MetricBasis.observed,
        )
      ],
    );

    final restored = repoDetailDigestFromJson(repoDetailDigestToJson(digest));

    expect(restored.activities.single.type, RepoActivityType.release);
    expect(restored.activities.single.title, 'published: v1.3.0');
    expect(restored.activities.single.actorLogin, 'octocat');
  });

  test('legacy repo detail cache without activities decodes as empty', () {
    final json = repoDetailDigestToJson(const RepoDetailDigest(repo: _repo, contributors: [], relatedRepos: [], primaryTrend: [1], compareTrend: [0.5], activities: []))..remove('activities');

    expect(repoDetailDigestFromJson(json).activities, isEmpty);
  });
}

const _repo = RepoEntity(fullName: 'owner/repo', description: 'Repository', language: 'Dart', starCount: 10, starDelta: 1, forkCount: 2, accentArgb: 0xFF00A389);
