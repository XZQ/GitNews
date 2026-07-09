import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_provenance.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/network/parallel.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';
import 'github_tech_hotspot_cache_codec.dart';
import 'github_tech_hotspot_digest_builder.dart';
import 'github_tech_hotspot_queries.dart';
import 'local_tech_hotspot_repository.dart';
import 'tech_hotspot_history_dao.dart';

const Duration techHotspotRemoteCacheTtl = CacheTtlConfig.techHotspot;

/* 
*基于 GitHub Search 的 AI 雷达远端仓库。
*/
class GithubTechHotspotRepository implements TechHotspotRepository {
  const GithubTechHotspotRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    TechHotspotHistoryDao? history,
    TechHotspotRepository fallback = const LocalTechHotspotRepository(),
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _history = history,
        _fallback = fallback,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final TechHotspotHistoryDao? _history;
  final TechHotspotRepository _fallback;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;

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
    if (_isRateLimited?.call() ?? false) {
      return cached ?? _fallback.getDigest();
    }

    try {
      final digest = await _fetchDigest(now);
      await _cache.upsert(
        key: _cacheKey,
        payload: techHotspotDigestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      _maybeReportRateLimit(e);
      AppLogger.warn(
        'githubTechHotspotFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDigest();
    }
  }

  void _maybeReportRateLimit(Object error) {
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
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
    if (json == null) {
      return null;
    }
    try {
      return techHotspotDigestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubTechHotspotCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<TechHotspotDigest> _fetchDigest(DateTime now) async {
    final fetched = await gatherAll<GithubTechHotspotTopicResult>(
      [
        for (final query in techHotspotTopicQueries) _fetchTopic(query, now),
      ],
      tag: 'githubTechHotspotFetch',
    );
    final results = await _withObservedHistory(fetched, now);
    final languages = buildTechHotspotLanguages(results);
    final tags = buildTechHotspotTags(results);
    return TechHotspotDigest(
      languages: languages,
      topics: results.map((result) => result.topic).toList(growable: false),
      heatTrend: buildTechHotspotHeatTrend(results),
      hotTags: tags,
    );
  }

  Future<GithubTechHotspotTopicResult> _fetchTopic(
    TechHotspotTopicQuery query,
    DateTime now,
  ) async {
    try {
      final cutoff = now.toUtc().subtract(const Duration(days: 30));
      final response = await _dio.get<Map<String, Object?>>(
        ApiEndpointsConfig.githubSearchRepositoriesPath,
        queryParameters: {
          'q': '(${query.query}) in:name,description,readme stars:>30 pushed:>=${GitHubApiSupport.formatDate(cutoff)} archived:false',
          'sort': 'stars',
          'order': 'desc',
          'per_page': 10,
        },
        options: Options(headers: GitHubApiSupport.headers(token: _token)),
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

  GithubTechHotspotTopicResult _parseTopic(
    TechHotspotTopicQuery query,
    Map<String, Object?> data,
  ) {
    final total = GitHubJson.intValue(data['total_count']);
    final items = GitHubJson.list(
      data['items'],
    ).map(GitHubJson.map).toList(growable: false);
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
    return GithubTechHotspotTopicResult(
      topic: TechTopic(
        id: query.id,
        name: query.name,
        category: query.category,
        heat: heat,
        growth: growth,
        mentions: total,
        relatedRepos: relatedRepos,
        summary: query.summary,
        provenance: DataProvenance.live,
        growthProvenance: DataProvenance.estimated,
      ),
      languages: languages,
    );
  }

  Future<List<GithubTechHotspotTopicResult>> _withObservedHistory(
    List<GithubTechHotspotTopicResult> results,
    DateTime now,
  ) async {
    final history = _history;
    if (history == null || results.isEmpty) {
      return results;
    }
    return Future.wait([
      for (final result in results) _withTopicHistory(result, history, now),
    ]);
  }

  Future<GithubTechHotspotTopicResult> _withTopicHistory(
    GithubTechHotspotTopicResult result,
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
    if (trend == null) {
      return result;
    }
    return GithubTechHotspotTopicResult(
      topic: copyTechHotspotTopic(
        topic,
        growth: trend.growth,
        growthProvenance: trend.provenance,
      ),
      languages: result.languages,
      heatTrend: recentTechHotspotHeatValues(trend.heatValues),
    );
  }
}
