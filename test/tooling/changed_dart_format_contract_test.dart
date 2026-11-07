import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changed Dart format check pins splat targets to an array', () {
    final script = File('tools/check_changed_dart_format.ps1').readAsStringSync();
    final declaration = script.split('\n').firstWhere((line) => line.contains('formatTargets = if'), orElse: () => '');

    expect(declaration.trimLeft().startsWith('[string[]]'), isTrue, reason: '单元素数组经 if 表达式赋值会退化成标量，splat 标量会把路径逐字符传给 dart；必须显式声明 [string[]]');
    expect(script, contains('@formatTargets'));
    expect(script, contains('--set-exit-if-changed'));
    expect(script, contains('single element'), reason: '保留根因注释，避免后续维护者删除数组类型标注');
    expect(script, contains(r'[IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)'), reason: 'root 与候选路径必须用同一 API 规范化，才能对仓库外的 -Root 正确判定包含关系');
  });
}
