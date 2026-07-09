import 'package:flutter/foundation.dart';

/* 
*受控日志门面。
*- debug 模式:走 `debugPrint`,可在控制台 / dev tools 看到。
*- release 模式:`kReleaseMode` 下完全 no-op,避免 PII / 内部异常
*泄露到 Windows `stderr` 或被附加到应用日志。
*使用约束:**只**记录 `AppException.kind` 与受控 meta,不要打印完整
*异常对象 / 堆栈 / SQL / 文件路径。
*/
class AppLogger {
  const AppLogger._();

  static void warn(String tag, {Map<String, Object?> meta = const {}}) {
    if (kReleaseMode) {
      return;
    }
    final parts = [tag, for (final e in meta.entries) '${e.key}=${e.value}'];
    debugPrint('[warn] ${parts.join(" ")}');
  }

  static void error(
    String tag, {
    Object? kind,
    Map<String, Object?> meta = const {},
  }) {
    if (kReleaseMode) {
      return;
    }
    final parts = [tag, if (kind != null) 'kind=$kind'];
    debugPrint('[error] ${parts.join(" ")}');
  }
}
