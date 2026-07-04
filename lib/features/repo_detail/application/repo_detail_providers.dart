import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_repo_detail_repository.dart';
import '../data/local_repo_detail_repository.dart';
import '../domain/repo_detail_repository.dart';

final repoDetailRepositoryProvider = Provider<RepoDetailRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  return GithubRepoDetailRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    snapshotHistory: ref.watch(repoSnapshotHistoryDaoProvider),
    token: token,
  );
});

final localRepoDetailRepositoryProvider = Provider<RepoDetailRepository>((ref) {
  return const LocalRepoDetailRepository();
});

final repoDetailDigestProvider =
    FutureProvider.family<RepoDetailDigest, String>((ref, fullName) {
  return ref.watch(repoDetailRepositoryProvider).getDetail(fullName);
});
