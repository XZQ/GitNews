import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_repo_detail_repository.dart';
import '../data/local_repo_detail_repository.dart';
import '../domain/repo_detail_repository.dart';

final repoDetailRepositoryProvider = Provider<RepoDetailRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return GithubRepoDetailRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    snapshotHistory: ref.watch(repoSnapshotHistoryDaoProvider),
    token: token,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final localRepoDetailRepositoryProvider = Provider<RepoDetailRepository>((ref) {
  return const LocalRepoDetailRepository();
});

final repoDetailResultProvider = FutureProvider.family<DataResult<RepoDetailDigest>, String>((ref, fullName) {
  return ref.watch(repoDetailRepositoryProvider).getDetail(fullName);
});

final repoDetailDigestProvider = FutureProvider.family<RepoDetailDigest, String>((ref, fullName) async {
  return (await ref.watch(repoDetailResultProvider(fullName).future)).data;
});
