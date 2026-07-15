import 'package:dio/dio.dart';

import '../domain/data_freshness.dart';
import '../errors/app_exception.dart';
import '../storage/json_snapshot_cache_dao.dart';
import 'github_api_support.dart';

class GitHubResourceCache {
  const GitHubResourceCache({required Dio dio, required JsonSnapshotCacheDao cache, String? token, String cacheScope = 'anonymous', DateTime Function()? now})
      : _dio = dio,
        _cache = cache,
        _token = token,
        _cacheScope = cacheScope,
        _now = now ?? DateTime.now;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final String _cacheScope;
  final DateTime Function() _now;

  Future<DataResult<Map<String, Object?>>> getObject({required String url, Map<String, Object?>? queryParameters, bool force = false}) {
    return _get<Map<String, Object?>>(url: url, queryParameters: queryParameters, force: force, kind: 'object', decode: (raw) => GitHubJson.map(raw));
  }

  Future<DataResult<List<Object?>>> getList({required String url, Map<String, Object?>? queryParameters, bool force = false}) {
    return _get<List<Object?>>(url: url, queryParameters: queryParameters, force: force, kind: 'list', decode: GitHubJson.list);
  }

  Future<DataResult<T>> _get<T>({required String url, required String kind, required T Function(Object? raw) decode, Map<String, Object?>? queryParameters, bool force = false}) async {
    final key = cacheKey(scope: _cacheScope, method: 'GET', url: url, queryParameters: queryParameters);
    if (force) {
      await _cache.delete(key);
    }
    var entry = await _readEntry(key);
    T? cached;
    if (entry.payload != null) {
      try {
        final payloadKind = entry.payload!['kind'];
        if (payloadKind != kind || !entry.payload!.containsKey('data')) {
          throw const FormatException('Unexpected cached resource payload');
        }
        cached = decode(entry.payload!['data']);
      } catch (_) {
        await _cache.delete(key);
        entry = const EtaggedEntry();
      }
    }

    try {
      final response = await _dio.get<Object?>(
        url,
        queryParameters: queryParameters,
        options: Options(headers: GitHubApiSupport.headers(token: _token, etag: entry.etag), validateStatus: (status) => status == 200 || status == 304),
      );
      if (response.statusCode == 304) {
        if (cached == null) {
          throw AppException(kind: AppExceptionKind.cache, meta: {'op': 'githubResource.304WithoutPayload', 'key': key});
        }
        await _cache.upsertWithEtag(key: key, payload: {'kind': kind, 'data': cached}, etag: entry.etag, now: _now());
        return DataResult(data: cached, freshness: DataFreshness.freshCache);
      }
      if (response.statusCode != 200) {
        throw AppException(kind: AppExceptionKind.server, meta: {'statusCode': response.statusCode});
      }
      final data = decode(response.data);
      await _cache.upsertWithEtag(key: key, payload: {'kind': kind, 'data': data}, etag: response.headers.value('etag'), now: _now());
      return DataResult(data: data, freshness: DataFreshness.live);
    } on DioException catch (error) {
      throw GitHubApiSupport.toAppException(error, now: _now);
    } on FormatException catch (error, stack) {
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    } on TypeError catch (error, stack) {
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    }
  }

  Future<EtaggedEntry> _readEntry(String key) async {
    try {
      return await _cache.readWithEtag(key);
    } on AppException {
      await _cache.delete(key);
      return const EtaggedEntry();
    }
  }

  static String cacheKey({required String scope, required String method, required String url, Map<String, Object?>? queryParameters}) {
    final query = queryParameters == null || queryParameters.isEmpty ? '' : _canonicalQuery(queryParameters);
    return 'github_resource:v1:$scope:${method.toUpperCase()}:$url$query';
  }

  static String _canonicalQuery(Map<String, Object?> parameters) {
    final keys = parameters.keys.toList()..sort();
    final pairs = <String>[];
    for (final key in keys) {
      final value = parameters[key];
      if (value is Iterable<Object?>) {
        for (final item in value) {
          pairs.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('$item')}');
        }
      } else {
        pairs.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('$value')}');
      }
    }
    return '?${pairs.join('&')}';
  }
}
