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
  };
}

RepoEntity githubRepoEntityFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return RepoEntity(
    fullName: GitHubJson.string(json['fullName']),
    description: GitHubJson.string(json['description']),
    language: GitHubJson.string(json['language']),
    starCount: GitHubJson.intValue(json['starCount']),
    starDelta: GitHubJson.intValue(json['starDelta']),
    forkCount: GitHubJson.intValue(json['forkCount']),
    accentArgb: GitHubJson.intValue(json['accentArgb']),
    valueBasis: _basisFromJson(json, 'valueBasis', 'valueProvenance'),
    trendBasis: _basisFromJson(json, 'trendBasis', 'trendProvenance'),
    trend: json['trend'] == null ? null : GitHubJson.doubleList(json['trend']),
  );
}

MetricBasis _basisFromJson(
  Map<String, Object?> json,
  String key,
  String legacyKey,
) {
  final name = GitHubJson.nullableString(json[key]);
  return name == null
      ? MetricBasis.fromLegacyName(
          GitHubJson.nullableString(json[legacyKey]),
        )
      : MetricBasis.fromName(name);
}
