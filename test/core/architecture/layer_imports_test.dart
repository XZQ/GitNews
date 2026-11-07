import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/*
*架构边界回归(AGENTS.md / Architecture)。
*
*展示层不得直接依赖 feature data;跨 feature 共享应走 core/domain、
*core/config 或 lib/shared。这里通过静态 import 图做机械约束:
*- 硬规则:展示层 -> 任意 feature/data 必须为零(当前即为零)。
*- 冻结规则:跨 feature 引用其它 feature 的展示层 widget 不得增长。
*  现存 9 处作为基线,每治理一条就从基线扣除一条,直到归零。
*
*仅解析相对 import/export;条件导入与代码生成不在本测试范围内。
*/
void main() {
  test('architecture scan actually covers the lib tree', () {
    expect(_dartFiles(), greaterThan(300));
  });

  test('presentation must not import feature data layers', () {
    final violations = _collect()['presentationToData']!;
    expect(violations, isEmpty, reason: '展示层不得直接依赖 feature data 类: $violations');
  });

  test('cross-feature presentation imports must not grow', () {
    const baseline = 9;
    final violations = _collect()['crossPresentation']!;
    expect(violations.length, lessThanOrEqualTo(baseline), reason: '跨 feature 引用其它 feature 的展示层 widget 只允许减少,不允许新增: $violations');
  });
}

final RegExp _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

int _dartFiles() {
  return Directory('lib').listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).length;
}

Map<String, List<String>> _collect() {
  final presentationToData = <String>[];
  final crossPresentation = <String>[];
  for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final source = _normalized(file.path);
    for (final match in _importPattern.allMatches(file.readAsStringSync())) {
      final target = match.group(1)!;
      if (target.startsWith('dart:') || target.startsWith('package:')) {
        continue;
      }
      final resolved = _normalized(p.join(p.dirname(source), target));
      final fromFeature = _featureOf(source);
      final toFeature = _featureOf(resolved);
      final sourceIsPresentation = RegExp(r'/(presentation|widgets)/').hasMatch(source);
      final targetIsPresentation = RegExp(r'/(presentation|widgets)/').hasMatch(resolved);
      if (sourceIsPresentation && toFeature != null && RegExp(r'lib/features/[^/]+/data/').hasMatch(resolved)) {
        presentationToData.add('$source -> $target');
      }
      if (fromFeature != null && toFeature != null && fromFeature != toFeature && targetIsPresentation) {
        crossPresentation.add('$source -> $target');
      }
    }
  }
  return {'presentationToData': presentationToData, 'crossPresentation': crossPresentation};
}

String _normalized(String path) {
  return p.normalize(path).replaceAll(r'\', '/');
}

String? _featureOf(String path) {
  return RegExp(r'lib/features/([^/]+)/').firstMatch(path)?.group(1);
}
