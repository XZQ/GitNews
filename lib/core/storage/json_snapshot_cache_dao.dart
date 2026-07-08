import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';
import 'cache_meta_dao.dart';

/* 
*通用 JSON 快照缓存 DAO。
*用于结构尚未稳定、但需要本地 TTL 缓存的远端聚合数据。
*/
class JsonSnapshotCacheDao {
  JsonSnapshotCacheDao(this._db, this._meta);

  final DatabaseExecutor _db;
  final CacheMetaDao _meta;

  static const String _table = 'json_snapshot_cache';

  Future<Map<String, Object?>?> read(String key) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['payload_json'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['payload_json'] as String)
          as Map<String, Object?>;
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'jsonSnapshot.read', 'key': key},
      );
    }
  }

  Future<void> upsert({
    required String key,
    required Map<String, Object?> payload,
    required DateTime now,
  }) async {
    try {
      await _db.insert(
          _table,
          {
            'cache_key': key,
            'payload_json': jsonEncode(payload),
            'cached_at': now.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _meta.upsert(key, now);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'jsonSnapshot.upsert', 'key': key},
      );
    }
  }

  Future<bool> isFresh({
    required String key,
    required Duration ttl,
    required DateTime now,
  }) async {
    final last = await _meta.lastFetched(key);
    if (last == null) return false;
    return now.difference(last) < ttl;
  }

  Future<void> delete(String key) async {
    try {
      await _db.delete(_table, where: 'cache_key = ?', whereArgs: [key]);
      await _meta.delete(key);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'jsonSnapshot.delete', 'key': key},
      );
    }
  }

  /* 
  *读取 payload 和 ETag(若曾写入)。
  */
  Future<EtaggedEntry> readWithEtag(String key) async {
    final payload = await read(key);
    final etag = await _meta.readEtag(key);
    return EtaggedEntry(payload: payload, etag: etag);
  }

  /* 
  *同时写 payload 与 ETag。etag 为 null 时保留既有 etag 不变。
  */
  Future<void> upsertWithEtag({
    required String key,
    required Map<String, Object?> payload,
    required DateTime now,
    String? etag,
  }) async {
    await upsert(key: key, payload: payload, now: now);
    if (etag != null) {
      await _meta.writeEtag(key, etag);
    }
  }
}

/* 
*缓存项与对应的 ETag。
*/
class EtaggedEntry {
  const EtaggedEntry({this.payload, this.etag});
  final Map<String, Object?>? payload;
  final String? etag;
}
