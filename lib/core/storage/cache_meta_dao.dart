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
      final rows = await _db.query(_table, columns: ['last_fetched_at'], where: 'cache_key = ?', whereArgs: [cacheKey], limit: 1);
      if (rows.isEmpty) {
        return null;
      }
      final ms = rows.first['last_fetched_at'] as int?;
      if (ms == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'lastFetched', 'cacheKey': cacheKey});
    }
  }

  /*
  *写入或更新 cache_key 的 last_fetched_at 为 [at]。
  *单条 UPSERT:query+insert/update 两步在并发下会互相覆盖。
  *成功验证清除 ext2 失败标记,保留 payload_hash / ext1 等列。
  */
  Future<void> upsert(String cacheKey, DateTime at) async {
    try {
      await _db.rawInsert(
        'INSERT INTO $_table(cache_key, last_fetched_at) VALUES(?, ?) '
        'ON CONFLICT(cache_key) DO UPDATE SET last_fetched_at=excluded.last_fetched_at, ext2=NULL',
        [cacheKey, at.millisecondsSinceEpoch],
      );
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'upsert', 'cacheKey': cacheKey});
    }
  }

  /* 验证失败独立于最后成功拉取时间;不推进 last_fetched_at。 */
  Future<void> markValidationFailed(String cacheKey) async {
    await _db.rawInsert(
      'INSERT INTO $_table(cache_key, last_fetched_at, ext2) VALUES(?, 0, ?) '
      'ON CONFLICT(cache_key) DO UPDATE SET ext2=excluded.ext2',
      [cacheKey, 'validation_failed'],
    );
  }

  Future<bool> hasFailedValidation(String cacheKey) async {
    final rows = await _db.query(_table, columns: ['ext2'], where: 'cache_key = ?', whereArgs: [cacheKey], limit: 1);
    return rows.isNotEmpty && rows.first['ext2'] == 'validation_failed';
  }

  /* 删除单条 cache_key 的 meta(例如该查询被显式失效时)。 */
  Future<void> delete(String cacheKey) async {
    try {
      await _db.delete(_table, where: 'cache_key = ?', whereArgs: [cacheKey]);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'delete', 'cacheKey': cacheKey});
    }
  }

  /* 
  *读取 cache_key 对应的 ETag(存于 payload_hash 列);不存在返回 null。
  */
  Future<String?> readEtag(String cacheKey) async {
    try {
      final rows = await _db.query(_table, columns: ['payload_hash'], where: 'cache_key = ?', whereArgs: [cacheKey], limit: 1);
      if (rows.isEmpty) {
        return null;
      }
      return rows.first['payload_hash'] as String?;
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'readEtag', 'cacheKey': cacheKey});
    }
  }

  /* 读取 HTTP 条件请求的 ETag 与 Last-Modified。 */
  Future<HttpCacheValidators> readValidators(String cacheKey) async {
    try {
      final rows = await _db.query(_table, columns: ['payload_hash', 'ext1'], where: 'cache_key = ?', whereArgs: [cacheKey], limit: 1);
      if (rows.isEmpty) {
        return const HttpCacheValidators();
      }
      return HttpCacheValidators(etag: rows.first['payload_hash'] as String?, lastModified: rows.first['ext1'] as String?);
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'readValidators', 'cacheKey': cacheKey});
    }
  }

  /* 
  *写入或覆盖 cache_key 对应的 ETag(payload_hash 列),
  *保留已存在的 last_fetched_at(若行不存在则用 0 占位)。
  */
  Future<void> writeEtag(String cacheKey, String etag) async {
    try {
      await _db.rawInsert(
        'INSERT INTO $_table(cache_key, last_fetched_at, payload_hash) VALUES(?, 0, ?) '
        'ON CONFLICT(cache_key) DO UPDATE SET payload_hash=excluded.payload_hash',
        [cacheKey, etag],
      );
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'writeEtag', 'cacheKey': cacheKey});
    }
  }

  /* 覆盖保存 HTTP 校验器;传 null 会清理对应旧值。 */
  Future<void> writeValidators(String cacheKey, HttpCacheValidators validators) async {
    try {
      await _db.rawInsert(
        'INSERT INTO $_table(cache_key, last_fetched_at, payload_hash, ext1) VALUES(?, 0, ?, ?) '
        'ON CONFLICT(cache_key) DO UPDATE SET payload_hash=excluded.payload_hash, ext1=excluded.ext1',
        [cacheKey, validators.etag, validators.lastModified],
      );
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'writeValidators', 'cacheKey': cacheKey});
    }
  }

  /*
  *批量清理超过 [retainFor] 未刷新的 cache_meta 行(最佳努力,失败不抛)。
  *返回被删除的 key,调用方据此联动清理 payload,避免孤儿快照无限增长。
  *last_fetched_at=0 的占位行(仅存 ETag/失败标记)不清理:它们没有
  *「上次成功拉取」语义,清掉会丢失条件请求校验器。
  *excludePrefixes 用于豁免用户数据键(观测历史等),由装配层传入。
  */
  Future<List<String>> pruneStale({required DateTime now, required Duration retainFor, List<String> excludePrefixes = const []}) async {
    try {
      final threshold = now.toUtc().millisecondsSinceEpoch - retainFor.inMilliseconds;
      final exclusions = [for (var i = 0; i < excludePrefixes.length; i++) 'cache_key NOT LIKE ?'];
      final where = ['last_fetched_at < ?', 'last_fetched_at > 0', ...exclusions].join(' AND ');
      final args = <Object?>[threshold, for (final prefix in excludePrefixes) '$prefix%'];
      final rows = await _db.query(_table, columns: ['cache_key'], where: where, whereArgs: args);
      final keys = [for (final row in rows) row['cache_key']! as String];
      if (keys.isEmpty) {
        return const [];
      }
      final placeholders = List.filled(keys.length, '?').join(',');
      await _db.delete(_table, where: 'cache_key IN ($placeholders)', whereArgs: keys);
      return keys;
    } catch (e) {
      AppLogger.warn('cacheMetaPrune', meta: {'error': e.runtimeType.toString()});
      return const [];
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
