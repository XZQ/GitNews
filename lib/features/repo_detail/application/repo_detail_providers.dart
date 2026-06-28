import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_repo_detail_repository.dart';
import '../domain/repo_detail_repository.dart';

final repoDetailRepositoryProvider = Provider<RepoDetailRepository>((ref) {
  return const LocalRepoDetailRepository();
});

final repoDetailDigestProvider =
    FutureProvider.family<RepoDetailDigest, String>((ref, fullName) {
  return ref.watch(repoDetailRepositoryProvider).getDetail(fullName);
});
