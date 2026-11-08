import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/di/repository_feed_providers.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_project_repository.dart';
import '../data/local_project_repository.dart';
import '../domain/project_repository.dart';

/*
 *project 仓库的装配。
 *
 *`RepositoryFeed` 由组合根注入(core 只声明抽象),因此本文件不认识 trending 等其它
 *feature——project 需要的只是「一份仓库摘要流」这个能力,而不是某个实现。
 */
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  final token = ref.watch(githubTokenControllerProvider);
  return GithubProjectRepository(
    repositoryFeed: ref.watch(repositoryFeedProvider),
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: token.token,
    cacheScope: token.cacheScope,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final localProjectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return LocalProjectRepository(repositoryFeed: ref.watch(repositoryFeedProvider));
});
