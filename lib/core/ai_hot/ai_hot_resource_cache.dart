import 'package:dio/dio.dart';

import '../domain/data_freshness.dart';
import '../errors/app_exception.dart';
import '../storage/cache_meta_dao.dart';
import '../storage/json_snapshot_cache_dao.dart';
import 'ai_hot_api_support.dart';

/*
*AI HOT REST/RSS 条件请求与快照缓存。
*每个 URL + query 组合独立保存 payload、ETag 和 Last-Modified;
*304 刷新快照时间,远程失败时明确回退 stale cache。
*/
class AiHotResourceCache {
  const AiHotResourceCache({required Dio dio, required JsonSnapshotCacheDao cache, DateTime Function()? now}) : _dio = dio, _cache = cache, _now = now ?? DateTime.now;

  // 复用项目超时与重试链的 HTTP 客户端。
  final Dio _dio;

  // 持久化 payload 与 HTTP 校验器的快照缓存。
  final JsonSnapshotCacheDao _cache;

  // 可测试时钟。
  final DateTime Function() _now;

  /* 请求 JSON object,支持 TTL、304 与 stale fallback。 */
  Future<DataResult<Map<String, Object?>>> getObject({required String url, required Duration ttl, Map<String, Object?>? queryParameters, bool force = false}) {
    return _get<Map<String, Object?>>(
      url: url,
      ttl: ttl,
      kind: 'object',
      accept: AiHotApiSupport.jsonAccept,
      queryParameters: queryParameters,
      force: force,
      responseType: ResponseType.json,
      decode: _decodeObject,
    );
  }

  /* 请求 RSS/Atom/XML 文本,支持 ETag 与 Last-Modified。 */
  Future<DataResult<String>> getText({required String url, required Duration ttl, bool force = false}) {
    return _get<String>(url: url, ttl: ttl, kind: 'text', accept: AiHotApiSupport.feedAccept, force: force, responseType: ResponseType.plain, decode: _decodeText);
  }

  Future<DataResult<T>> _get<T>({
    required String url,
    required Duration ttl,
    required String kind,
    required String accept,
    required ResponseType responseType,
    required T Function(Object? raw) decode,
    Map<String, Object?>? queryParameters,
    bool force = false,
  }) async {
    final key = cacheKey(url: url, queryParameters: queryParameters);
    var entry = await _readEntry(key);
    T? cached;
    if (entry.payload != null) {
      try {
        if (entry.payload!['kind'] != kind || !entry.payload!.containsKey('data')) {
          throw const FormatException('Unexpected AI HOT cache payload');
        }
        cached = decode(entry.payload!['data']);
      } catch (_) {
        await _cache.delete(key);
        entry = const ValidatedCacheEntry();
      }
    }
    final now = _now().toUtc();
    if (!force && cached != null && await _cache.isFresh(key: key, ttl: ttl, now: now)) {
      return DataResult(data: cached, freshness: DataFreshness.freshCache);
    }

    try {
      final response = await _dio.get<Object?>(
        url,
        queryParameters: queryParameters,
        options: Options(
          responseType: responseType,
          headers: AiHotApiSupport.headers(accept: accept, validators: entry.validators),
          validateStatus: (status) => status == 200 || status == 304,
        ),
      );
      if (response.statusCode == 304) {
        if (cached == null) {
          throw AppException(kind: AppExceptionKind.cache, meta: {'op': 'aiHotResource.304WithoutPayload', 'key': key});
        }
        await _cache.upsertWithValidators(
          key: key,
          payload: {'kind': kind, 'data': cached},
          validators: _responseValidators(response, fallback: entry.validators),
          now: now,
        );
        return DataResult(data: cached, freshness: DataFreshness.freshCache);
      }
      if (response.statusCode != 200) {
        throw AppException(kind: AppExceptionKind.server, meta: {'statusCode': response.statusCode});
      }
      final data = decode(response.data);
      await _cache.upsertWithValidators(key: key, payload: {'kind': kind, 'data': data}, validators: _responseValidators(response), now: now);
      return DataResult(data: data, freshness: DataFreshness.live);
    } on DioException catch (error) {
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      throw AiHotApiSupport.toAppException(error);
    } on FormatException catch (error, stack) {
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    } on TypeError catch (error, stack) {
      if (cached != null) {
        return DataResult(data: cached, freshness: DataFreshness.staleCache);
      }
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    }
  }

  /* 生成按 query 隔离的稳定快照 key。 */
  static String cacheKey({required String url, Map<String, Object?>? queryParameters}) {
    final query = queryParameters == null || queryParameters.isEmpty ? '' : _canonicalQuery(queryParameters);
    return 'ai_hot_resource:v1:GET:$url$query';
  }

  Future<ValidatedCacheEntry> _readEntry(String key) async {
    try {
      return await _cache.readWithValidators(key);
    } on AppException {
      await _cache.delete(key);
      return const ValidatedCacheEntry();
    }
  }

  static HttpCacheValidators _responseValidators(Response<Object?> response, {HttpCacheValidators fallback = const HttpCacheValidators()}) {
    return HttpCacheValidators(etag: response.headers.value('etag') ?? fallback.etag, lastModified: response.headers.value('last-modified') ?? fallback.lastModified);
  }

  static Map<String, Object?> _decodeObject(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    throw const FormatException('Expected JSON object');
  }

  static String _decodeText(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    throw const FormatException('Expected non-empty text');
  }

  static String _canonicalQuery(Map<String, Object?> parameters) {
    final keys = parameters.keys.toList()..sort();
    return '?${[for (final key in keys) '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('${parameters[key]}')}'].join('&')}';
  }
}
