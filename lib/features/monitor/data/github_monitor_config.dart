const String githubMonitorCacheKey = 'monitor:github:default:v1';

const List<String> githubMonitorDefaultRepos = [
  'openai/codex',
  'modelcontextprotocol/servers',
  'langchain-ai/langgraph',
  'anthropics/claude-code',
  'ollama/ollama',
  'vllm-project/vllm',
];

String githubMonitorRelativeTime(DateTime? date, DateTime now) {
  if (date == null) {
    return '未知';
  }
  final diff = now.toUtc().difference(date.toUtc());
  if (diff.inMinutes < 10) {
    return '刚刚';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前';
  }
  return '${diff.inDays} 天前';
}

String githubMonitorCompactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

int githubMonitorActivityScore({
  required int stars,
  required int forks,
  required int openIssues,
  required DateTime? pushedAt,
  required DateTime now,
}) {
  final pushedBoost = pushedAt == null ? 1 : (30 - now.toUtc().difference(pushedAt).inDays).clamp(1, 30);
  return ((stars / 180) + (forks / 40) + (openIssues / 12) + pushedBoost).round().clamp(1, 9999);
}

List<double> githubMonitorEstimatedRepoTrend(int stars) {
  final base = stars / 160;
  return List<double>.generate(
    7,
    (index) => (base * (0.72 + index * 0.06)).roundToDouble(),
  );
}
