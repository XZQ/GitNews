String repoDetailCacheKey(String fullName) {
  return 'repo_detail:github:${fullName.toLowerCase()}:v1';
}

List<double> estimatedRepoTrend(int stars, double scale) {
  final base = stars / 150 * scale;
  return List<double>.generate(7, (index) => (base * (0.72 + index * 0.06)).roundToDouble());
}

int repoDetailActivityScore({required int stars, required int forks, required int issues, required DateTime? pushedAt, required DateTime now}) {
  final pushedBoost = pushedAt == null ? 1 : (30 - now.toUtc().difference(pushedAt).inDays).clamp(1, 30);
  return ((stars / 180) + (forks / 35) + (issues / 16) + pushedBoost).round().clamp(1, 9999);
}
