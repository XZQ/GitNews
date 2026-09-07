import '../domain/data_freshness.dart';
import '../domain/repo_entity.dart';
import 'github_api_support.dart';

Map<String, Object?> githubRepoEntityToJson(RepoEntity repo) {
  return {
    'fullName': repo.fullName,
    'description': repo.description,
    'language': repo.language,
    'starCount': repo.starCount,
    'starDelta': repo.starDelta,
    'forkCount': repo.forkCount,
    'accentArgb': repo.accentArgb,
    'valueBasis': repo.valueBasis.name,
    'trendBasis': repo.trendBasis.name,
    'trend': repo.trend,
    'trendDates': repo.trendDates.map((date) => date.toUtc().toIso8601String()).toList(),
    'starDeltaDays': repo.starDeltaDays,
  };
}

RepoEntity githubRepoEntityFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return RepoEntity(
    fullName: GitHubJson.string(json['fullName']),
    description: GitHubJson.nullableString(json['description']) ?? '',
    language: GitHubJson.nullableString(json['language']) ?? 'Unknown',
    starCount: GitHubJson.intValue(json['starCount']),
    starDelta: GitHubJson.intValue(json['starDelta']),
    forkCount: GitHubJson.intValue(json['forkCount']),
    accentArgb: GitHubJson.intValue(json['accentArgb']),
    valueBasis: _basisFromJson(json, 'valueBasis', 'valueProvenance'),
    trendBasis: _basisFromJson(json, 'trendBasis', 'trendProvenance'),
    trend: json['trend'] == null ? null : GitHubJson.doubleList(json['trend']),
    trendDates: json['trendDates'] == null ? const [] : [for (final date in GitHubJson.list(json['trendDates'])) DateTime.parse(GitHubJson.string(date)).toUtc()],
    starDeltaDays: json['starDeltaDays'] == null ? 30 : GitHubJson.intValue(json['starDeltaDays']),
  );
}

MetricBasis _basisFromJson(Map<String, Object?> json, String key, String legacyKey) {
  final name = GitHubJson.nullableString(json[key]);
  return name == null ? MetricBasis.fromLegacyName(GitHubJson.nullableString(json[legacyKey])) : MetricBasis.fromName(name);
}
