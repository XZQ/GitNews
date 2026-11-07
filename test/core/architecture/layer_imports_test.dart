import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/*
*架构边界回归(AGENTS.md / Architecture)。
*
*分层约定:
*- `lib/app/` 是应用组合根,负责装配各 feature 的页面、provider 与首页;
*- `lib/features/<feature>/` 之间不得互相 import,共享走 core/domain、
*  core/config 或 lib/shared;
*- 展示层不得直接依赖 feature 的 data 层,组合根同样不得触碰 data 层。
*
*这里通过静态 import 图做机械约束:相对 import 与 `package:github_news/` 前缀
*都会被解析,条件导入与代码生成不在本测试范围内。
*/
void main() {
  test('architecture scan actually covers the lib tree', () {
    expect(_dartFiles(), greaterThan(300));
  });

  test('presentation must not import feature data layers', () {
    final violations = _collect().presentationToData;
    expect(violations, isEmpty, reason: '展示层不得直接依赖 feature data 类: $violations');
  });

  test('features must not import other features', () {
    final violations = _collect().crossFeature;
    expect(violations, isEmpty, reason: 'feature 之间只允许通过 core 或 lib/shared 共享,发现直接引用: $violations');
  });

  test('composition root must not reach feature data layers', () {
    final violations = _collect().appToData;
    expect(violations, isEmpty, reason: '组合根只装配 application 与 presentation,不得直接依赖 feature data: $violations');
  });

  test('composition root owns the home page', () {
    expect(File('lib/app/app.dart').existsSync(), isTrue, reason: '应用根 widget 应位于 lib/app/app.dart');
    expect(Directory('lib/app/home').existsSync(), isTrue, reason: '首页属于组合根,应位于 lib/app/home/');
    expect(Directory('lib/features/home').existsSync(), isFalse, reason: '首页不应留在 features 目录下');
  });
}

const String _packagePrefix = 'github_news/';

final RegExp _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
final RegExp _presentationPath = RegExp(r'/(presentation|widgets)/');
final RegExp _featureDataPath = RegExp(r'lib/features/[^/]+/data/');
final RegExp _featurePath = RegExp(r'lib/features/([^/]+)/');

int _dartFiles() {
  return Directory('lib').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).length;
}

_ArchitectureScan _collect() {
  final presentationToData = <String>[];
  final crossFeature = <String>[];
  final appToData = <String>[];
  for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final source = _normalized(file.path);
    for (final match in _importPattern.allMatches(file.readAsStringSync())) {
      final target = _resolve(source, match.group(1)!);
      if (target == null) {
        continue;
      }
      final targetIsFeatureData = _featureDataPath.hasMatch(target);
      if (_presentationPath.hasMatch(source) && targetIsFeatureData) {
        presentationToData.add('$source -> $target');
      }
      if (source.startsWith('lib/app/') && targetIsFeatureData) {
        appToData.add('$source -> $target');
      }
      final fromFeature = _featureOf(source);
      final toFeature = _featureOf(target);
      if (fromFeature != null && toFeature != null && fromFeature != toFeature) {
        crossFeature.add('$source -> $target');
      }
    }
  }
  return _ArchitectureScan(presentationToData: presentationToData, crossFeature: crossFeature, appToData: appToData);
}

class _ArchitectureScan {
  const _ArchitectureScan({required this.presentationToData, required this.crossFeature, required this.appToData});

  final List<String> presentationToData;
  final List<String> crossFeature;
  final List<String> appToData;
}

/* 解析单个 import 目标;SDK 库与包外依赖返回 null。 */
String? _resolve(String source, String target) {
  if (target.startsWith('dart:')) {
    return null;
  }
  if (target.startsWith('package:')) {
    if (!target.startsWith('package:$_packagePrefix')) {
      return null;
    }
    return _normalized('lib/${target.substring('package:$_packagePrefix'.length)}');
  }
  return _normalized(p.join(p.dirname(source), target));
}

String _normalized(String path) {
  return p.normalize(path).replaceAll(r'\', '/');
}

String? _featureOf(String path) {
  return _featurePath.firstMatch(path)?.group(1);
}
