import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/github_api_support.dart';
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
    // 种子列表没有请求的仓库时,构造同名占位实体并标 unavailable:
    // 借用无关仓库的名称/星数/贡献者会把种子数据冒充成请求对象。
    final repo = all.firstWhere(
      (item) => item.fullName == decoded,
      orElse: () => RepoEntity(
        fullName: decoded,
        description: '',
        language: 'Unknown',
        starCount: 0,
        starDelta: 0,
        forkCount: 0,
        accentArgb: GitHubApiSupport.languageColor('Unknown'),
        valueBasis: MetricBasis.unavailable,
        trendBasis: MetricBasis.unavailable,
      ),
    );
    final relatedRepos = all.where((item) => item.fullName != repo.fullName).take(4).toList(growable: false);
    return DataResult(
      freshness: DataFreshness.seed,
      data: RepoDetailDigest(
        repo: repo,
        contributors: DemoData.contributors.map((e) => e.toEntity()).toList(),
        relatedRepos: relatedRepos,
        primaryTrend: const [],
        compareTrend: const [],
        activities: const [],
      ),
    );
  }
}
