import 'dart:async';

import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/* 
*并发执行多个独立任务,带可选的单任务超时。
*
*商业级健壮性:
*- 单个任务失败(含超时)只记录并跳过,不会拖垮整批
*  ([Future.wait] 默认 `eagerError:false` 也不会取消兄弟任务);
*- 仅当**全部**任务失败时才抛出 [AppException],交由上层走缓存/种子兜底。
*
*适用于「逐项独立拉取、丢一两个不影响整体」的列表聚合场景
*(如监控仓库 / 技术热点 topic / 项目贡献者聚合)。
*不适用于「丢一项即数据缺失」的富集场景(如为每个仓库补历史趋势),
*那种场景应保留原项而非丢弃。
*/
Future<List<T>> gatherAll<T>(
  Iterable<Future<T>> futures, {
  Duration? timeout,
  String tag = 'gatherAll',
}) async {
  final list = futures.toList();
  if (list.isEmpty) {
    return const [];
  }

  Future<T?> guard(int index, Future<T> future) async {
    try {
      if (timeout == null) {
        return await future;
      }
      return await future.timeout(timeout);
    } on TimeoutException {
      AppLogger.warn(tag, meta: {'index': index, 'error': 'TimeoutException'});
      return null;
    } catch (e) {
      AppLogger.warn(
        tag,
        meta: {'index': index, 'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  final guarded = <Future<T?>>[
    for (var i = 0; i < list.length; i++) guard(i, list[i]),
  ];
  final results = await Future.wait<T?>(guarded, eagerError: false);
  final ok = results.whereType<T>().toList(growable: false);
  if (ok.isEmpty) {
    throw AppException(
      kind: AppExceptionKind.network,
      cause: StateError('all $tag calls failed (${list.length})'),
    );
  }
  return ok;
}
