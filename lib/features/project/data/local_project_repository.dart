import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repository_feed.dart';
import '../domain/project_repository.dart';

/* 
*基于 [DemoData] + [TrendingRepository] 的本地项目仓库。
*/
class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository({required this.repositoryFeed});

  final RepositoryFeed repositoryFeed;

  @override
  Future<DataResult<ProjectDigest>> getDigest() async {
    final feed = (await repositoryFeed.load()).data;
    return DataResult(
      freshness: DataFreshness.seed,
      data: ProjectDigest(
        repos: feed.repos,
        contributors: DemoData.contributors.map((e) => e.toEntity()).toList(growable: false),
        primaryTrend: feed.primaryTrend,
        secondaryTrend: feed.secondaryTrend,
      ),
    );
  }
}
