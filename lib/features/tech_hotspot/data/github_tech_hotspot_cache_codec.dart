import '../../../core/domain/data_provenance.dart';
import '../../../core/github/github_api_support.dart';
import '../domain/tech_hotspot_models.dart';

Map<String, Object?> techHotspotDigestToJson(TechHotspotDigest digest) {
  return {
    'languages': digest.languages.map(_languageToJson).toList(),
    'topics': digest.topics.map(_topicToJson).toList(),
    'heatTrend': digest.heatTrend.map(_heatToJson).toList(),
    'hotTags': digest.hotTags,
  };
}

TechHotspotDigest techHotspotDigestFromJson(Map<String, Object?> json) {
  return TechHotspotDigest(
    languages:
        GitHubJson.list(json['languages']).map(_languageFromJson).toList(),
    topics: GitHubJson.list(json['topics']).map(_topicFromJson).toList(),
    heatTrend: GitHubJson.list(json['heatTrend']).map(_heatFromJson).toList(),
    hotTags: GitHubJson.list(json['hotTags'])
        .map(GitHubJson.string)
        .toList(growable: false),
  );
}

Map<String, Object?> _languageToJson(LanguageStat language) {
  return {
    'name': language.name,
    'percent': language.percent,
    'delta': language.delta,
    'color': language.color,
    'repoCount': language.repoCount,
  };
}

LanguageStat _languageFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return LanguageStat(
    name: GitHubJson.string(json['name']),
    percent: GitHubJson.doubleValue(json['percent']),
    delta: GitHubJson.doubleValue(json['delta']),
    color: GitHubJson.intValue(json['color']),
    repoCount: GitHubJson.intValue(json['repoCount']),
    provenance: DataProvenance.estimated,
  );
}

Map<String, Object?> _topicToJson(TechTopic topic) {
  return {
    'id': topic.id,
    'name': topic.name,
    'category': topic.category,
    'heat': topic.heat,
    'growth': topic.growth,
    'mentions': topic.mentions,
    'relatedRepos': topic.relatedRepos,
    'summary': topic.summary,
    'provenance': topic.provenance.name,
    'growthProvenance': topic.growthProvenance.name,
  };
}

TechTopic _topicFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return TechTopic(
    id: GitHubJson.string(json['id']),
    name: GitHubJson.string(json['name']),
    category: GitHubJson.string(json['category']),
    heat: GitHubJson.intValue(json['heat']),
    growth: GitHubJson.doubleValue(json['growth']),
    mentions: GitHubJson.intValue(json['mentions']),
    relatedRepos: GitHubJson.intValue(json['relatedRepos']),
    summary: GitHubJson.string(json['summary']),
    provenance: _provenanceFromJson(
      json['provenance'],
      fallback: DataProvenance.live,
    ),
    growthProvenance: _provenanceFromJson(
      json['growthProvenance'],
      fallback: DataProvenance.estimated,
    ),
  );
}

Map<String, Object?> _heatToJson(TechHeatPoint point) {
  return {'label': point.label, 'value': point.value};
}

TechHeatPoint _heatFromJson(Object? raw) {
  final json = GitHubJson.map(raw);
  return TechHeatPoint(
    label: GitHubJson.string(json['label']),
    value: GitHubJson.doubleValue(json['value']),
  );
}

DataProvenance _provenanceFromJson(
  Object? raw, {
  required DataProvenance fallback,
}) {
  final name = GitHubJson.nullableString(raw);
  if (name == null) return fallback;
  return DataProvenance.values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}
