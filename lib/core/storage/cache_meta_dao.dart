import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../errors/app_exception.dart';

/// 通用 cache_key → last_fetched_at 映射。
///
/// 任何「按查询走 TTL」的模块(如 AI 资讯分类列表)都用这张表记录
/// 「我上次拉远端是什么时候」,从而决定要不要后台刷新。
///
/// payload_hash / ext1..ext3 是为后续版本预留的扩展字段。
class CacheMetaDao {
  CacheMetaDao(this._db);

  final DatabaseExecutor _db;

  static const String _table = 'cache_meta';

  /// 读取 cache_key 对应的最后拉取时刻;不存在返回 null。
  Future<DateTime?> lastFetched(String cacheKey) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['last_fetched_at'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final ms = rows.first['last_fetched_at'] as int?;
      if (ms == null) return null;
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

  /// 写入或更新 cache_key 的 last_fetched_at 为 [at]。
  Future<void> upsert(String cacheKey, DateTime at) async {
    try {
      await _db.insert(
        _table,
        {
          'cache_key': cacheKey,
          'last_fetched_at': at.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'upsert', 'cacheKey': cacheKey},
      );
    }
  }

  /// 删除单条 cache_key 的 meta(例如该查询被显式失效时)。
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
}
