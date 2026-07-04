import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';
import 'local_tech_hotspot_repository.dart';

const Duration techHotspotRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub Search 的 AI 雷达远端仓库。
class GithubTechHotspotRepository implements TechHotspotRepository {
  const GithubTechHotspotRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    TechHotspotRepository fallback = const LocalTechHotspotRepository(),
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final TechHotspotRepository _fallback;

  static const String _cacheKey = 'tech_hotspot:github:default:v1';
  static const List<_TopicQuery> _queries = [
    _TopicQuery(
      id: 'github-agent',
      name: 'Agent 框架',
      category: 'Agent',
      query: 'agent OR ai-agent OR llm-agent OR langgraph OR autogen',
      summary: 'GitHub 上 Agent 编排、长任务代理和多智能体项目的综合热度。',
    ),
    _TopicQuery(
      id: 'github-mcp',
      name: 'MCP 协议',
      category: 'Agent',
      query: 'mcp OR model-context-protocol OR modelcontextprotocol',
      summary: '模型连接工具、数据源和本地应用的开放协议生态热度。',
    ),
    _TopicQuery(
      id: 'github-ai-coding',
      name: 'AI Coding 工具',
      category: 'DevTools',
      query:
          'coding agent OR copilot OR code assistant OR claude-code OR codex',
      summary: '从代码补全到任务代理的 AI Coding 项目增长趋势。',
    ),
    _TopicQuery(
      id: 'github-rag',
      name: 'RAG 工程化',
      category: 'Data',
      query: 'rag OR retrieval augmented generation OR vector database',
      summary: '检索增强生成、向量数据库、重排和知识库链路的工程热度。',
    ),
    _TopicQuery(
      id: 'github-local-llm',
      name: '本地推理',
      category: 'Infra',
      query: 'llama.cpp OR ollama OR vllm OR local llm',
      summary: '本地模型推理、端侧部署和低延迟推理工具链热度。',
    ),
  ];

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
    final results = await Future.wait([
      for (final query in _queries) _fetchTopic(query, now),
    ]);
    final languages = _buildLanguages(results);
    final tags = _buildTags(results);
    return TechHotspotDigest(
      languages: languages,
      topics: results.map((result) => result.topic).toList(growable: false),
      heatTrend: _buildHeatTrend(results),
      hotTags: tags,
    );
  }

  Future<_TopicResult> _fetchTopic(_TopicQuery query, DateTime now) async {
    try {
      final cutoff = now.toUtc().subtract(const Duration(days: 30));
      final response = await _dio.get<Map<String, Object?>>(
        '/search/repositories',
        queryParameters: {
          'q':
              '(${query.query}) in:name,description,readme stars:>30 pushed:>=${_formatDate(cutoff)} archived:false',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 10,
        },
        options: Options(headers: _headers()),
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

  _TopicResult _parseTopic(_TopicQuery query, Map<String, Object?> data) {
    final total = _int(data['total_count']);
    final items = _list(data['items']).map(_map).toList(growable: false);
    final stars = items.fold<int>(
      0,
      (sum, item) => sum + _int(item['stargazers_count']),
    );
    final languages = <String, int>{};
    for (final item in items) {
      final language = _nullableString(item['language']) ?? 'Unknown';
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
      ),
      languages: languages,
    );
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
        color: _languageColor(entry.key),
        repoCount: entry.value,
      );
    }).toList(growable: false);
  }

  List<TechHeatPoint> _buildHeatTrend(List<_TopicResult> results) {
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

  Map<String, Object?> _headers() {
    final token = _token?.trim();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'GitHubNews/0.1 (Flutter)',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
      languages: _list(json['languages']).map(_languageFromJson).toList(),
      topics: _list(json['topics']).map(_topicFromJson).toList(),
      heatTrend: _list(json['heatTrend']).map(_heatFromJson).toList(),
      hotTags: _list(json['hotTags']).map(_string).toList(growable: false),
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
    final json = _map(raw);
    return LanguageStat(
      name: _string(json['name']),
      percent: _double(json['percent']),
      delta: _double(json['delta']),
      color: _int(json['color']),
      repoCount: _int(json['repoCount']),
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
    };
  }

  TechTopic _topicFromJson(Object? raw) {
    final json = _map(raw);
    return TechTopic(
      id: _string(json['id']),
      name: _string(json['name']),
      category: _string(json['category']),
      heat: _int(json['heat']),
      growth: _double(json['growth']),
      mentions: _int(json['mentions']),
      relatedRepos: _int(json['relatedRepos']),
      summary: _string(json['summary']),
    );
  }

  Map<String, Object?> _heatToJson(TechHeatPoint point) {
    return {'label': point.label, 'value': point.value};
  }

  TechHeatPoint _heatFromJson(Object? raw) {
    final json = _map(raw);
    return TechHeatPoint(
      label: _string(json['label']),
      value: _double(json['value']),
    );
  }

  List<Object?> _list(Object? raw) {
    if (raw is List<Object?>) return raw;
    throw const FormatException('Expected list');
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const FormatException('Expected object');
  }

  String _string(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw const FormatException('Expected string');
  }

  String? _nullableString(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    throw const FormatException('Expected nullable string');
  }

  int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }

  double _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    throw const FormatException('Expected double');
  }

  int _languageColor(String language) {
    return switch (language.toLowerCase()) {
      'typescript' => 0xFF3178C6,
      'javascript' => 0xFFF1E05A,
      'python' => 0xFF3572A5,
      'rust' => 0xFFDEA584,
      'go' => 0xFF00ADD8,
      'dart' => 0xFF00B4AB,
      'c++' => 0xFFF34B7D,
      _ => 0xFF64748B,
    };
  }
}

class _TopicQuery {
  const _TopicQuery({
    required this.id,
    required this.name,
    required this.category,
    required this.query,
    required this.summary,
  });

  final String id;
  final String name;
  final String category;
  final String query;
  final String summary;
}

class _TopicResult {
  const _TopicResult({
    required this.topic,
    required this.languages,
  });

  final TechTopic topic;
  final Map<String, int> languages;
}
