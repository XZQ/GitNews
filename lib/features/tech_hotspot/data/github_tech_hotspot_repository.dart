import 'package:dio/dio.dart';

import '../../../core/domain/data_provenance.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';
import 'github_tech_hotspot_queries.dart';
import 'local_tech_hotspot_repository.dart';
import 'tech_hotspot_history_dao.dart';

const Duration techHotspotRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub Search 的 AI 雷达远端仓库。
class GithubTechHotspotRepository implements TechHotspotRepository {
  const GithubTechHotspotRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    TechHotspotHistoryDao? history,
    TechHotspotRepository fallback = const LocalTechHotspotRepository(),
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _history = history,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final TechHotspotHistoryDao? _history;
  final TechHotspotRepository _fallback;

  static const String _cacheKey = 'tech_hotspot:github:default:v1';

  @override
  Future<TechHotspotDigest> getDigest() async {
    final now = _now();
    final cached = await _readCached();
    if (cached != null &&
        await _cache.isFresh(
          key: _cacheKey,
          ttl: techHotspotRemoteCacheTtl,
          now: now,
        )) {
      return cached;
    }

    try {
      final digest = await _fetchDigest(now);
      await _cache.upsert(
        key: _cacheKey,
        payload: _digestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      AppLogger.warn(
        'githubTechHotspotFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDigest();
    }
  }

  @override
  Future<TechTopic?> getById(String id) async {
    final digest = await getDigest();
    return digest.topics.where((topic) => topic.id == id).firstOrNull;
  }

  @override
  Future<List<TechTopic>> allTopics() async => (await getDigest()).topics;

  Future<TechHotspotDigest?> _readCached() async {
    final json = await _cache.read(_cacheKey);
    if (json == null) return null;
    try {
      return _digestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubTechHotspotCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<TechHotspotDigest> _fetchDigest(DateTime now) async {
    final fetched = await Future.wait([
      for (final query in techHotspotTopicQueries) _fetchTopic(query, now),
    ]);
    final results = await _withObservedHistory(fetched, now);
    final languages = _buildLanguages(results);
    final tags = _buildTags(results);
    return TechHotspotDigest(
      languages: languages,
      topics: results.map((result) => result.topic).toList(growable: false),
      heatTrend: _buildHeatTrend(results),
      hotTags: tags,
    );
  }

  Future<_TopicResult> _fetchTopic(
    TechHotspotTopicQuery query,
    DateTime now,
  ) async {
    try {
      final cutoff = now.toUtc().subtract(const Duration(days: 30));
      final response = await _dio.get<Map<String, Object?>>(
        '/search/repositories',
        queryParameters: {
          'q':
              '(${query.query}) in:name,description,readme stars:>30 pushed:>=${GitHubApiSupport.formatDate(cutoff)} archived:false',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 10,
        },
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _parseTopic(query, data);
    } on DioException catch (e) {
      throw e.toAppException();
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  _TopicResult _parseTopic(
    TechHotspotTopicQuery query,
    Map<String, Object?> data,
  ) {
    final total = GitHubJson.intValue(data['total_count']);
    final items = GitHubJson.list(data['items'])
        .map(GitHubJson.map)
        .toList(growable: false);
    final stars = items.fold<int>(
      0,
      (sum, item) => sum + GitHubJson.intValue(item['stargazers_count']),
    );
    final languages = <String, int>{};
    for (final item in items) {
      final language = GitHubJson.nullableString(item['language']) ?? 'Unknown';
      languages.update(language, (value) => value + 1, ifAbsent: () => 1);
    }
    final heat = ((stars / 1200) + (total / 80)).round().clamp(35, 100);
    final relatedRepos = total.clamp(0, 99999);
    final growth = (heat / 3.2).clamp(4, 42).toDouble();
    return _TopicResult(
      topic: TechTopic(
        id: query.id,
        name: query.name,
        category: query.category,
        heat: heat,
        growth: growth,
        mentions: total,
        relatedRepos: relatedRepos,
        summary: query.summary,
        provenance: DataProvenance.observed,
        growthProvenance: DataProvenance.estimated,
      ),
      languages: languages,
    );
  }

  Future<List<_TopicResult>> _withObservedHistory(
    List<_TopicResult> results,
    DateTime now,
  ) async {
    final history = _history;
    if (history == null || results.isEmpty) return results;
    return Future.wait([
      for (final result in results) _withTopicHistory(result, history, now),
    ]);
  }

  Future<_TopicResult> _withTopicHistory(
    _TopicResult result,
    TechHotspotHistoryDao history,
    DateTime now,
  ) async {
    final topic = result.topic;
    await history.record(
      id: topic.id,
      heat: topic.heat,
      mentions: topic.mentions,
      relatedRepos: topic.relatedRepos,
      capturedAt: now,
    );
    final trend = await history.trend(topic.id);
    if (trend == null) return result;
    return _TopicResult(
      topic: _copyTopic(
        topic,
        growth: trend.growth,
        growthProvenance: trend.provenance,
      ),
      languages: result.languages,
      heatTrend: _recentHeatValues(trend.heatValues),
    );
  }

  List<double> _recentHeatValues(List<double> values) {
    if (values.length <= 7) return values;
    return values.sublist(values.length - 7);
  }

  List<LanguageStat> _buildLanguages(List<_TopicResult> results) {
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
    if (total == 0) return const [];
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(8).map((entry) {
      return LanguageStat(
        name: entry.key,
        percent: entry.value / total * 100,
        delta: 0,
        color: GitHubApiSupport.languageColor(entry.key),
        repoCount: entry.value,
        provenance: DataProvenance.estimated,
      );
    }).toList(growable: false);
  }

  List<TechHeatPoint> _buildHeatTrend(List<_TopicResult> results) {
    final observed = [
      for (final result in results)
        if (result.heatTrend != null && result.heatTrend!.length >= 2)
          result.heatTrend!,
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
    final total =
        results.fold<int>(0, (sum, result) => sum + result.topic.heat);
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return List<TechHeatPoint>.generate(labels.length, (index) {
      return TechHeatPoint(
        label: labels[index],
        value: (total / results.length * (0.76 + index * 0.05)).roundToDouble(),
      );
    });
  }

  List<String> _trendLabels(int count) {
    if (count <= 0) return const [];
    if (count == 2) return const ['起点', '今日'];
    return List<String>.generate(count, (index) {
      if (index == 0) return '起点';
      if (index == count - 1) return '今日';
      return '+$index';
    });
  }

  List<String> _buildTags(List<_TopicResult> results) {
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

  Map<String, Object?> _digestToJson(TechHotspotDigest digest) {
    return {
      'languages': digest.languages.map(_languageToJson).toList(),
      'topics': digest.topics.map(_topicToJson).toList(),
      'heatTrend': digest.heatTrend.map(_heatToJson).toList(),
      'hotTags': digest.hotTags,
    };
  }

  TechHotspotDigest _digestFromJson(Map<String, Object?> json) {
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
        fallback: DataProvenance.observed,
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

TechTopic _copyTopic(
  TechTopic topic, {
  double? growth,
  DataProvenance? growthProvenance,
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
    provenance: topic.provenance,
    growthProvenance: growthProvenance ?? topic.growthProvenance,
  );
}

class _TopicResult {
  const _TopicResult({
    required this.topic,
    required this.languages,
    this.heatTrend,
  });

  final TechTopic topic;
  final Map<String, int> languages;
  final List<double>? heatTrend;
}
