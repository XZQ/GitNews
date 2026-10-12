import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

/*
*可暂停或拒绝安全存储操作的内存替身，用于凭据生命周期回归。
*/
class ControlledSecureStorage extends Mock implements FlutterSecureStorage {
  ControlledSecureStorage([Map<String, String> initial = const {}]) : values = {...initial} {
    when(() => read(key: any(named: 'key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final snapshot = values[key];
      final gate = nextReadGate;
      nextReadGate = null;
      nextReadStarted?.complete();
      nextReadStarted = null;
      if (gate != null) {
        await gate.future;
      }
      if (failRead) {
        throw StateError('Secure read unavailable');
      }
      return snapshot;
    });
    when(
      () => write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      final gate = nextWriteGate;
      nextWriteGate = null;
      nextWriteStarted?.complete();
      nextWriteStarted = null;
      if (gate != null) {
        await gate.future;
      }
      if (failWrite) {
        throw StateError('Secure write unavailable');
      }
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    });
    when(() => delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      if (failDelete) {
        throw StateError('Secure delete unavailable');
      }
      values.remove(invocation.namedArguments[#key] as String);
    });
  }

  // 模拟安全存储内容；只使用测试凭据。
  final Map<String, String> values;

  // 下一次读取的暂停点和启动信号。
  Completer<void>? nextReadGate;
  Completer<void>? nextReadStarted;

  // 下一次写入的暂停点和启动信号。
  Completer<void>? nextWriteGate;
  Completer<void>? nextWriteStarted;

  // 独立模拟读取、写入和删除失败。
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
}
