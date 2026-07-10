import '../../../core/domain/data_freshness.dart';
import '../../../core/github/github_api_support.dart';
import '../domain/tech_hotspot_models.dart';

class GithubTechHotspotTopicResult {
  const GithubTechHotspotTopicResult({
    required this.topic,
    required this.languages,
    this.heatTrend,
  });

  final TechTopic topic;
  final Map<String, int> languages;
  final List<double>? heatTrend;
}

List<LanguageStat> buildTechHotspotLanguages(
  List<GithubTechHotspotTopicResult> results,
) {
  final counts = <String, int>{};
  for (final result in results) {
    for (final entry in result.languages.entries) {
      counts.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
  final total = counts.values.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) {
    return const [];
  }
  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(8).map((entry) {
    return LanguageStat(
      name: entry.key,
      percent: entry.value / total * 100,
      delta: 0,
      color: GitHubApiSupport.languageColor(entry.key),
      repoCount: entry.value,
      basis: MetricBasis.estimated,
    );
  }).toList(growable: false);
}

List<TechHeatPoint> buildTechHotspotHeatTrend(
  List<GithubTechHotspotTopicResult> results,
) {
  final observed = [
    for (final result in results)
      if (result.heatTrend != null && result.heatTrend!.length >= 2) result.heatTrend!,
  ];
  if (observed.isNotEmpty) {
    final pointCount = observed.fold<int>(
      observed.first.length,
      (count, trend) => trend.length < count ? trend.length : count,
    );
    final labels = _trendLabels(pointCount);
    return List<TechHeatPoint>.generate(pointCount, (index) {
      final sum = observed.fold<double>(0, (total, trend) {
        return total + trend[trend.length - pointCount + index];
      });
      return TechHeatPoint(
        label: labels[index],
        value: (sum / observed.length).roundToDouble(),
      );
    });
  }
  final total = results.fold<int>(0, (sum, result) => sum + result.topic.heat);
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return List<TechHeatPoint>.generate(labels.length, (index) {
    return TechHeatPoint(
      label: labels[index],
      value: (total / results.length * (0.76 + index * 0.05)).roundToDouble(),
    );
  });
}

List<String> buildTechHotspotTags(List<GithubTechHotspotTopicResult> results) {
  final tags = <String>[
    for (final result in results) result.topic.name,
    'GitHub',
    'Open Source',
    'Repository',
    'Tool Use',
    'Inference',
    'Vector DB',
  ];
  return tags.toSet().take(16).toList(growable: false);
}

List<double> recentTechHotspotHeatValues(List<double> values) {
  if (values.length <= 7) {
    return values;
  }
  return values.sublist(values.length - 7);
}

TechTopic copyTechHotspotTopic(
  TechTopic topic, {
  double? growth,
  MetricBasis? growthBasis,
}) {
  return TechTopic(
    id: topic.id,
    name: topic.name,
    category: topic.category,
    heat: topic.heat,
    growth: growth ?? topic.growth,
    mentions: topic.mentions,
    relatedRepos: topic.relatedRepos,
    summary: topic.summary,
    valueBasis: topic.valueBasis,
    growthBasis: growthBasis ?? topic.growthBasis,
  );
}

List<String> _trendLabels(int count) {
  if (count <= 0) {
    return const [];
  }
  if (count == 2) {
    return const ['起点', '今日'];
  }
  return List<String>.generate(count, (index) {
    if (index == 0) {
      return '起点';
    }
    if (index == count - 1) {
      return '今日';
    }
    return '+$index';
  });
}
