import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/* 
*通用 cache_key → last_fetched_at 映射。
*任何「按查询走 TTL」的模块(如 AI 资讯分类列表)都用这张表记录
*「我上次拉远端是什么时候」,从而决定要不要后台刷新。
*payload_hash / ext1..ext3 是为后续版本预留的扩展字段。
*/
class CacheMetaDao {
  CacheMetaDao(this._db);

  final DatabaseExecutor _db;

  static const String _table = 'cache_meta';

  /* 
  *读取 cache_key 对应的最后拉取时刻;不存在返回 null。
  */
  Future<DateTime?> lastFetched(String cacheKey) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['last_fetched_at'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      final ms = rows.first['last_fetched_at'] as int?;
      if (ms == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'lastFetched', 'cacheKey': cacheKey},
      );
    }
  }

  /* 
  *写入或更新 cache_key 的 last_fetched_at 为 [at]。
  *保留已存在的 payload_hash / ext1..ext3 等列。
  */
  Future<void> upsert(String cacheKey, DateTime at) async {
    try {
      final existing = await _db.query(
        _table,
        columns: ['cache_key'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (existing.isEmpty) {
        await _db.insert(_table, {'cache_key': cacheKey, 'last_fetched_at': at.millisecondsSinceEpoch});
      } else {
        await _db.update(
          _table,
          {'last_fetched_at': at.millisecondsSinceEpoch},
          where: 'cache_key = ?',
          whereArgs: [cacheKey],
        );
      }
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'upsert', 'cacheKey': cacheKey},
      );
    }
  }

  /* 
  *删除单条 cache_key 的 meta(例如该查询被显式失效时)。
  */
  Future<void> delete(String cacheKey) async {
    try {
      await _db.delete(_table, where: 'cache_key = ?', whereArgs: [cacheKey]);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'delete', 'cacheKey': cacheKey},
      );
    }
  }

  /* 
  *读取 cache_key 对应的 ETag(存于 payload_hash 列);不存在返回 null。
  */
  Future<String?> readEtag(String cacheKey) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['payload_hash'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first['payload_hash'] as String?;
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'readEtag', 'cacheKey': cacheKey},
      );
    }
  }

  /* 读取 HTTP 条件请求的 ETag 与 Last-Modified。 */
  Future<HttpCacheValidators> readValidators(String cacheKey) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['payload_hash', 'ext1'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const HttpCacheValidators();
      }
      return HttpCacheValidators(
        etag: rows.first['payload_hash'] as String?,
        lastModified: rows.first['ext1'] as String?,
      );
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'readValidators', 'cacheKey': cacheKey},
      );
    }
  }

  /* 
  *写入或覆盖 cache_key 对应的 ETag(payload_hash 列),
  *保留已存在的 last_fetched_at(若行不存在则用 0 占位)。
  */
  Future<void> writeEtag(String cacheKey, String etag) async {
    try {
      final existing = await _db.query(
        _table,
        columns: ['cache_key'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (existing.isEmpty) {
        await _db.insert(_table, {'cache_key': cacheKey, 'last_fetched_at': 0, 'payload_hash': etag});
      } else {
        await _db.update(
          _table,
          {'payload_hash': etag},
          where: 'cache_key = ?',
          whereArgs: [cacheKey],
        );
      }
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'writeEtag', 'cacheKey': cacheKey},
      );
    }
  }

  /* 覆盖保存 HTTP 校验器;传 null 会清理对应旧值。 */
  Future<void> writeValidators(String cacheKey, HttpCacheValidators validators) async {
    try {
      final existing = await _db.query(
        _table,
        columns: ['cache_key'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      final values = <String, Object?>{
        'payload_hash': validators.etag,
        'ext1': validators.lastModified,
      };
      if (existing.isEmpty) {
        await _db.insert(
          _table,
          {'cache_key': cacheKey, 'last_fetched_at': 0, ...values},
        );
      } else {
        await _db.update(
          _table,
          values,
          where: 'cache_key = ?',
          whereArgs: [cacheKey],
        );
      }
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'writeValidators', 'cacheKey': cacheKey},
      );
    }
  }

  /*
  *批量清理超过 [retainFor] 未刷新的 cache_meta 行(最佳努力,失败不抛)。
  *用于启动时收敛无限增长的 cache_key 元数据;被清理的 key 下次拉取时会重建。
  */
  Future<int> pruneStale({required DateTime now, required Duration retainFor}) async {
    try {
      final threshold = now.toUtc().millisecondsSinceEpoch - retainFor.inMilliseconds;
      return _db.delete(_table, where: 'last_fetched_at < ?', whereArgs: [threshold]);
    } catch (e) {
      AppLogger.warn('cacheMetaPrune', meta: {'error': e.runtimeType.toString()});
      return 0;
    }
  }
}

/*
*HTTP 条件请求校验器。
*ETag 用于 If-None-Match,Last-Modified 用于 If-Modified-Since。
*/
class HttpCacheValidators {
  const HttpCacheValidators({this.etag, this.lastModified});

  // 当前资源 ETag。
  final String? etag;

  // 当前资源 Last-Modified HTTP 日期。
  final String? lastModified;
}
