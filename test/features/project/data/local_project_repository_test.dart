import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/domain/repository_feed.dart';
import 'package:github_news/features/project/data/local_project_repository.dart';

class _FakeRepositoryFeed implements RepositoryFeed {
  @override
  Future<DataResult<RepositoryFeedDigest>> load() async {
    return const DataResult(
      freshness: DataFreshness.live,
      data: RepositoryFeedDigest(
        repos: [
          RepoEntity(
            fullName: 'openai/codex',
            description: 'Coding agent',
            language: 'Rust',
            starCount: 100,
            starDelta: 10,
            forkCount: 20,
            accentArgb: 0xFF000000,
            valueBasis: MetricBasis.observed,
            trendBasis: MetricBasis.observed,
          ),
        ],
        primaryTrend: [1, 2],
        secondaryTrend: [2, 3],
      ),
    );
  }
}

void main() {
  test('project repository consumes only the Core repository feed', () async {
    final repository = LocalProjectRepository(
      repositoryFeed: _FakeRepositoryFeed(),
    );

    final result = await repository.getDigest();

    expect(result.data.repos.single.fullName, 'openai/codex');
    expect(result.data.primaryTrend, [1, 2]);
    expect(result.freshness, DataFreshness.seed);
  });
}
