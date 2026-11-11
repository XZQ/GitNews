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
      final rows = await _db.query(_table, columns: ['payload_json'], where: 'cache_key = ?', whereArgs: [key], limit: 1);
      if (rows.isEmpty) {
        return null;
      }
      return jsonDecode(rows.first['payload_json'] as String) as Map<String, Object?>;
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'jsonSnapshot.read', 'key': key});
    }
  }

  /*
  *更新快照；部分失败仅保存内容和失败状态，不推进成功验证时间。
  *payload 与 meta 在同一事务内写入:中途失败不会留下
  *「有 payload 无 meta」或「新 payload 配旧校验器」的不一致状态。
  */
  Future<void> upsert({required String key, required Map<String, Object?> payload, required DateTime now, bool validated = true}) async {
    try {
      final cachedAt = validated ? now.millisecondsSinceEpoch : (await _meta.lastFetched(key))?.millisecondsSinceEpoch ?? 0;
      final payloadJson = jsonEncode(payload);
      await _atomic((txn) async {
        await txn.insert(_table, {'cache_key': key, 'payload_json': payloadJson, 'cached_at': cachedAt}, conflictAlgorithm: ConflictAlgorithm.replace);
        final meta = CacheMetaDao(txn);
        if (validated) {
          await meta.upsert(key, now);
        } else {
          await meta.markValidationFailed(key);
        }
      });
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'jsonSnapshot.upsert', 'key': key});
    }
  }

  /* executor 是完整 Database 时用事务包裹;已是事务内 executor 则直接执行。 */
  Future<T> _atomic<T>(Future<T> Function(DatabaseExecutor txn) action) {
    final db = _db;
    if (db is Database) {
      return db.transaction(action);
    }
    return action(db);
  }

  Future<bool> isFresh({required String key, required Duration ttl, required DateTime now}) async {
    final last = await _meta.lastFetched(key);
    if (last == null) {
      return false;
    }
    return now.difference(last) < ttl && !await _meta.hasFailedValidation(key);
  }

  Future<void> markValidationFailed(String key) => _meta.markValidationFailed(key);

  Future<void> delete(String key) async {
    try {
      await _atomic((txn) async {
        await txn.delete(_table, where: 'cache_key = ?', whereArgs: [key]);
        await CacheMetaDao(txn).delete(key);
      });
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'jsonSnapshot.delete', 'key': key});
    }
  }

  /*
  *启动清理联动:meta 行被 prune 后,同步删除两张快照表里的 payload,
  *避免孤儿快照只增不减。表名来自 core 统一 schema。
  */
  static Future<void> pruneSnapshotPayloads(DatabaseExecutor db, List<String> keys) async {
    if (keys.isEmpty) {
      return;
    }
    final placeholders = List.filled(keys.length, '?').join(',');
    await db.delete(_table, where: 'cache_key IN ($placeholders)', whereArgs: keys);
    await db.delete('trending_snapshot_cache', where: 'cache_key IN ($placeholders)', whereArgs: keys);
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
  *三步在同一事务内,避免新 payload 配旧 ETag。
  */
  Future<void> upsertWithEtag({required String key, required Map<String, Object?> payload, required DateTime now, String? etag}) async {
    try {
      final payloadJson = jsonEncode(payload);
      final cachedAt = now.millisecondsSinceEpoch;
      await _atomic((txn) async {
        await txn.insert(_table, {'cache_key': key, 'payload_json': payloadJson, 'cached_at': cachedAt}, conflictAlgorithm: ConflictAlgorithm.replace);
        final meta = CacheMetaDao(txn);
        await meta.upsert(key, now);
        if (etag != null) {
          await meta.writeEtag(key, etag);
        }
      });
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'jsonSnapshot.upsertWithEtag', 'key': key});
    }
  }

  /* 读取 payload 与 ETag/Last-Modified 校验器。 */
  Future<ValidatedCacheEntry> readWithValidators(String key) async {
    final payload = await read(key);
    final validators = await _meta.readValidators(key);
    return ValidatedCacheEntry(payload: payload, validators: validators, validatedAt: await _meta.lastFetched(key));
  }

  /* 同时写入 payload 与完整 HTTP 校验器,同一事务保证一致。 */
  Future<void> upsertWithValidators({required String key, required Map<String, Object?> payload, required DateTime now, required HttpCacheValidators validators}) async {
    try {
      final payloadJson = jsonEncode(payload);
      final cachedAt = now.millisecondsSinceEpoch;
      await _atomic((txn) async {
        await txn.insert(_table, {'cache_key': key, 'payload_json': payloadJson, 'cached_at': cachedAt}, conflictAlgorithm: ConflictAlgorithm.replace);
        final meta = CacheMetaDao(txn);
        await meta.upsert(key, now);
        await meta.writeValidators(key, validators);
      });
    } catch (e, st) {
      throw AppException(kind: AppExceptionKind.cache, cause: e, stack: st, meta: {'op': 'jsonSnapshot.upsertWithValidators', 'key': key});
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

/*
*快照缓存与完整 HTTP 校验器。
*/
class ValidatedCacheEntry {
  const ValidatedCacheEntry({this.payload, this.validators = const HttpCacheValidators(), this.validatedAt});

  // 已解码的缓存快照。
  final Map<String, Object?>? payload;

  // 用于下次条件请求的校验器。
  final HttpCacheValidators validators;
  final DateTime? validatedAt;
}
