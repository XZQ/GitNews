import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/domain/data_freshness.dart';
import '../domain/repo_detail_repository.dart';

/* 
*基于本地模拟数据的仓库详情仓库。
*/
class LocalRepoDetailRepository implements RepoDetailRepository {
  const LocalRepoDetailRepository();

  @override
  Future<DataResult<RepoDetailDigest>> getDetail(String fullName) async {
    final all = [...DemoData.trending, ...DemoData.recent].map((e) => e.toEntity()).toList();
    final decoded = Uri.decodeComponent(fullName);
    final repo = all.firstWhere((item) => item.fullName == decoded, orElse: () => all.first);
    final relatedRepos = all.where((item) => item.fullName != repo.fullName).take(4).toList(growable: false);
    return DataResult(
      freshness: DataFreshness.seed,
      data: RepoDetailDigest(
        repo: repo,
        contributors: DemoData.contributors.map((e) => e.toEntity()).toList(),
        relatedRepos: relatedRepos,
        primaryTrend: DemoData.generateStarTrend(repo.starCount - 5000, 5000),
        compareTrend: DemoData.generateStarTrend(repo.starCount - 8000, 3500),
        activities: const [],
      ),
    );
  }
}
