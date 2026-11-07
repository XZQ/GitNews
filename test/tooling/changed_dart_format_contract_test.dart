import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changed Dart format check pins splat targets to an array', () {
    final script = File('tools/check_changed_dart_format.ps1').readAsStringSync();

    expect(script, contains('[string[]]\$formatTargets'), reason: '单元素数组经 if 表达式赋值会退化成标量，splat 标量会把路径逐字符传给 dart');
    expect(script, contains('@formatTargets'));
    expect(script, contains('--set-exit-if-changed'));
  });

  test('changed Dart format check passes when a CI base range contains one file', () async {
    final workspace = Directory.systemTemp.createTempSync('changed-dart-format-');
    addTearDown(() => workspace.deleteSync(recursive: true));

    final repo = Directory('${workspace.path}/repo');
    final source = File('${repo.path}/lib/good.dart');
    source.parent.createSync(recursive: true);
    source.writeAsStringSync('int add(int a, int b) => a + b;\n');

    Future<ProcessResult> git(List<String> arguments) {
      return Process.run('git', <String>['-C', repo.path, ...arguments]);
    }

    await git(<String>['init', '-q']);
    await git(<String>['add', '.']);
    await git(<String>['-c', 'user.name=Harness', '-c', 'user.email=harness@local', 'commit', '-q', '-m', 'base']);
    final base = await git(<String>['rev-parse', 'HEAD']);
    final baseSha = (base.stdout as String).trim();

    source.writeAsStringSync('int add(int a, int b) {\n  return a + b;\n}\n');
    await git(<String>['add', '.']);
    await git(<String>['-c', 'user.name=Harness', '-c', 'user.email=harness@local', 'commit', '-q', '-m', 'changed']);

    final scriptPath = File('tools/check_changed_dart_format.ps1').absolute.path;
    final result = await Process.run('powershell', <String>['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, '-Root', repo.path, '-BaseRef', baseSha]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('passed for 1 file(s)'));
    expect('${result.stdout}${result.stderr}', isNot(contains('No file or directory found at')));
  }, skip: !Platform.isWindows);
}
