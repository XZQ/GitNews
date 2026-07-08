/// GitHub rate limit 分桶。
class GitHubRateLimitBucket {
  const GitHubRateLimitBucket({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  final int limit;
  final int remaining;
  final DateTime resetAt;
}

/// GitHub rate limit 状态。
class GitHubRateLimitSnapshot {
  const GitHubRateLimitSnapshot({
    required this.core,
    required this.search,
    required this.checkedAt,
  });

  final GitHubRateLimitBucket core;
  final GitHubRateLimitBucket search;
  final DateTime checkedAt;
}
