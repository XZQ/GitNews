import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/features/repo_detail/data/local_repo_detail_repository.dart';

void main() {
  test('种子列表没有请求仓库时返回同名占位而不是借用无关仓库', () async {
    const repository = LocalRepoDetailRepository();

    final result = await repository.getDetail('some-owner/some-repo');

    expect(result.freshness, DataFreshness.seed);
    expect(result.data.repo.fullName, 'some-owner/some-repo');
    expect(result.data.repo.valueBasis, MetricBasis.unavailable);
    expect(result.data.repo.starCount, 0);
    expect(result.data.contributors, isNotEmpty);
  });

  test('种子列表包含请求仓库时正常返回种子详情', () async {
    const repository = LocalRepoDetailRepository();
    final anySeed = await repository.getDetail('any');
    final known = await repository.getDetail(anySeed.data.relatedRepos.first.fullName);

    expect(known.data.repo.fullName, anySeed.data.relatedRepos.first.fullName);
    expect(known.data.repo.valueBasis, isNot(MetricBasis.unavailable));
  });
}
