import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project/data/github_project_repository.dart';
import '../../features/project/data/local_project_repository.dart';
import '../../features/project/domain/project_repository.dart';
import '../../features/trending/application/trending_providers.dart';
import '../../features/trending/application/trending_repository_feed.dart';
import '../github/rate_limit_gate.dart';
import '../preferences/github_token_controller.dart';
import '../storage/storage_providers.dart';
import 'providers.dart';

final projectRepositoryFeedProvider = Provider<TrendingRepositoryFeed>((ref) {
  return TrendingRepositoryFeed(ref.watch(trendingRepositoryProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  final token = ref.watch(githubTokenControllerProvider);
  return GithubProjectRepository(
    repositoryFeed: ref.watch(projectRepositoryFeedProvider),
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: token.token,
    cacheScope: token.cacheScope,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final localProjectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return LocalProjectRepository(repositoryFeed: ref.watch(projectRepositoryFeedProvider));
});
