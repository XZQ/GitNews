import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/di/providers.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import '../domain/project_repository.dart';
import 'github_project_repository.dart';

/* 
*基于 [DemoData] + [TrendingRepository] 的本地项目仓库。
*/
class LocalProjectRepository implements ProjectRepository {
  const LocalProjectRepository({required this.trending});

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

// 依赖注入入口。
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final trending = ref.watch(trendingRepositoryProvider);
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return GithubProjectRepository(
    trending: trending,
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: ref.watch(githubTokenControllerProvider).token,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final localProjectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return LocalProjectRepository(
    trending: ref.watch(trendingRepositoryProvider),
  );
});
