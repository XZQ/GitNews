import 'package:dio/dio.dart';

import '../../../core/ai_hot/ai_hot_resource_cache.dart';
import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../domain/ai_hot_daily.dart';
import '../domain/ai_hot_status.dart';
import '../domain/ai_hot_topic.dart';
import 'dto/ai_hot_daily_codec.dart';
import 'dto/ai_hot_status_codec.dart';
import 'dto/ai_hot_topic_codec.dart';
import 'dto/ai_news_item_dto.dart';

/*
*AI HOT 公开 REST API 客户端。
*匿名只读、无需 token;通过 [AiHotResourceCache] 实现按 query 隔离的 TTL、ETag、304 与 stale fallback。
*/
class AiNewsApiClient {
  const AiNewsApiClient(this._resources);

  /* 用共享 Dio 与 SQLite 快照缓存构造客户端。 */
  factory AiNewsApiClient.create({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    DateTime Function()? now,
  }) {
    return AiNewsApiClient(
      AiHotResourceCache(dio: dio, cache: cache, now: now),
    );
  }

  static const String baseUrl = ApiEndpointsConfig.aiNewsBaseUrl;

  // REST/RSS 条件请求与快照缓存。
  final AiHotResourceCache _resources;

  /* 读取精选或最近 7 天公开池条目。 */
  Future<DataResult<AiNewsListResponseDto>> fetchItems({
    String? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
    bool force = false,
  }) async {
    final parameters = <String, Object?>{
      'mode': selectedOnly ? 'selected' : 'all',
      'take': 50,
      if (category != null) 'category': category,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (query != null && query.trim().length >= 2) 'q': query.trim(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiNewsItemsPath,
      queryParameters: parameters,
      ttl: CacheTtlConfig.aiNews,
      force: force,
    );
    return DataResult(
      data: AiNewsListResponseDto.fromJson(result.data),
      freshness: result.freshness,
    );
  }

  /* 读取当前多信源热点。 */
  Future<DataResult<List<AiHotTopic>>> fetchHotTopics({bool force = false}) async {
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotTopicsPath,
      ttl: CacheTtlConfig.aiHotTopics,
      force: force,
    );
    return DataResult(data: AiHotTopicCodec.list(result.data), freshness: result.freshness);
  }

  /* 读取最新官方日报。 */
  Future<DataResult<AiHotDailyReport>> fetchLatestDaily({bool force = false}) async {
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotDailyPath,
      ttl: CacheTtlConfig.aiHotDaily,
      force: force,
    );
    return DataResult(data: AiHotDailyCodec.report(result.data), freshness: result.freshness);
  }

  /* 读取指定 YYYY-MM-DD 官方日报。 */
  Future<DataResult<AiHotDailyReport>> fetchDaily(String date, {bool force = false}) async {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const AppException(kind: AppExceptionKind.parse, meta: {'field': 'date'});
    }
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotDailyByDatePath(date),
      ttl: CacheTtlConfig.aiHotDaily,
      force: force,
    );
    return DataResult(data: AiHotDailyCodec.report(result.data), freshness: result.freshness);
  }

  /* 读取最近日报索引。 */
  Future<DataResult<List<AiHotDailyEntry>>> fetchDailies({int take = 30, bool force = false}) async {
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotDailiesPath,
      queryParameters: {'take': take.clamp(1, 180)},
      ttl: CacheTtlConfig.aiHotDaily,
      force: force,
    );
    return DataResult(data: AiHotDailyCodec.entries(result.data), freshness: result.freshness);
  }

  /* 读取低流量内容指纹。 */
  Future<DataResult<AiHotFingerprint>> fetchFingerprint({bool force = false}) async {
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotFingerprintPath,
      ttl: CacheTtlConfig.aiHotFingerprint,
      force: force,
    );
    return DataResult(data: AiHotStatusCodec.fingerprint(result.data), freshness: result.freshness);
  }

  /* 读取 API 与 Skill 版本信息。 */
  Future<DataResult<AiHotVersion>> fetchVersion({bool force = false}) async {
    final result = await _resources.getObject(
      url: ApiEndpointsConfig.aiHotVersionPath,
      ttl: CacheTtlConfig.aiHotVersion,
      force: force,
    );
    return DataResult(data: AiHotStatusCodec.version(result.data), freshness: result.freshness);
  }
}
