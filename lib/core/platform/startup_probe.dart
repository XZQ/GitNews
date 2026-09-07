import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/app_logger.dart';

/*
*启动探针仅输出白名单状态，不包含异常原文、SQL、文件路径或用户内容。
*/
typedef StartupReporter = Future<void> Function(String status, {Object? error});

/* 返回可用于恢复页和烟测的稳定错误分类。 */
String startupFailureCode(Object? error) {
  final message = error.toString();
  if (message.contains('(error code: 126)')) {
    return 'native_library_or_dependency_missing';
  }
  if (message.contains('(error code: 127)')) {
    return 'native_symbol_missing';
  }
  if (message.contains('No native assets')) {
    return 'native_assets_missing';
  }
  if (message.contains('native function') || message.contains('Failed to lookup symbol')) {
    return 'native_symbol_unavailable';
  }
  if (message.contains('dynamic library') || message.contains('Failed to load')) {
    return 'native_library_unavailable';
  }
  if (error is DatabaseException) {
    if (error.toString().contains('no such module: fts5')) {
      return 'sqlite_fts5_unavailable';
    }
    if (error.toString().contains('Unable to load dynamic library')) {
      return 'sqlite_library_unavailable';
    }
    return 'sqlite_${error.getResultCode() ?? 'unknown'}';
  }
  if (error is FileSystemException) {
    return 'filesystem_${error.osError?.errorCode ?? 'unknown'}';
  }
  return 'initialization_failed';
}

/* 发布烟测显式配置输出文件时记录状态；普通运行不写额外日志。 */
Future<void> reportStartupProbe(String status, {Object? error}) async {
  final destination = Platform.environment['GITHUB_NEWS_STARTUP_REPORT'];
  if (destination == null || destination.isEmpty) {
    return;
  }
  try {
    final report = <String, Object?>{
      'status': status,
      'pid': pid,
      'recordedAt': DateTime.now().toUtc().toIso8601String(),
      if (error != null) 'failureCode': startupFailureCode(error),
      if (error != null) 'errorType': error.runtimeType.toString(),
      // 仅记录原生函数的编译期标识符，绝不记录异常原文。
      if (error is ArgumentError) 'nativeFunction': RegExp(r"native function '([a-zA-Z0-9_]+)'").firstMatch(error.toString())?.group(1),
    };
    await File(destination).writeAsString(jsonEncode(report), flush: true);
  } on FileSystemException {
    AppLogger.warn('startup_probe_write_failed');
  }
}
