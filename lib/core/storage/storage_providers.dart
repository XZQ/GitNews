import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_meta_dao.dart';
import 'local_database.dart';

/// 全局 [LocalDatabase] 单例。
///
/// **必须**在 `main()` 中 override,因为 DB 打开是异步副作用,
/// 不能在 Provider 内部懒加载(会与 `main()` 的 bootstrap 流程竞争)。
final appDatabaseProvider = Provider<LocalDatabase>(
  (ref) => throw StateError('appDatabaseProvider must be overridden in main()'),
);

/// 通用 [CacheMetaDao]:任何按 cache_key 走 TTL 的模块都注入这一个实例。
final cacheMetaDaoProvider = Provider<CacheMetaDao>(
  (ref) => CacheMetaDao(ref.watch(appDatabaseProvider).executor),
);

/// 容量管理辅助 Provider:供设置页等需要直接读取 DB 大小的地方使用。
///
/// 之所以不把 [LocalDatabase] 直接暴露给 UI,是为了让 UI 只能调用
/// 容量相关的几个方法,避免误用 executor 干扰业务层。
final storageSizeReporterProvider = Provider<StorageSizeReporter>(
  (ref) => StorageSizeReporter(ref.watch(appDatabaseProvider)),
);

/// 包装容量管理能力,隔离 UI 与底层 [LocalDatabase]。
class StorageSizeReporter {
  StorageSizeReporter(this._db);
  final LocalDatabase _db;

  int currentBytes() => _db.sizeInBytes();

  Future<void> clearAll() => _db.clearAll();
}
