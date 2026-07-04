import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/github_rate_limit_client.dart';

final githubRateLimitClientProvider = Provider<GitHubRateLimitClient>((ref) {
  return GitHubRateLimitClient(ref.watch(dioProvider));
});
