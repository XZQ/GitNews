import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import '../domain/project_repository.dart';

/// 基于 [DemoData] + [TrendingRepository] 的本地项目仓库。
class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository({
    required this.trending,
  });

  final TrendingRepository trending;

  @override
  Future<ProjectDigest> getDigest() async {
    final digest = await trending.getDigest();
    return ProjectDigest(
      repos: digest.allRepos,
      contributors: DemoData.contributors
          .map((e) => e.toEntity())
          .toList(growable: false),
      primaryTrend: digest.primaryTrend,
      secondaryTrend: digest.secondaryTrend,
    );
  }
}

/// 依赖注入入口。
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return LocalProjectRepository(
    trending: ref.watch(trendingRepositoryProvider),
  );
});
