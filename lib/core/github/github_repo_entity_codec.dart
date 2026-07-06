import '../domain/data_provenance.dart';
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
    'valueProvenance': repo.valueProvenance.name,
    'trendProvenance': repo.trendProvenance.name,
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
    valueProvenance: DataProvenance.fromName(
      GitHubJson.nullableString(json['valueProvenance']),
    ),
    trendProvenance: DataProvenance.fromName(
      GitHubJson.nullableString(json['trendProvenance']),
    ),
    trend: json['trend'] == null ? null : GitHubJson.doubleList(json['trend']),
  );
}
