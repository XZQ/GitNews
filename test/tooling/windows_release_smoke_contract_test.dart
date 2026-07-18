import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows smoke script validates artifacts and a visible window', () {
    final script = File('tools/windows_release_smoke.ps1').readAsStringSync();

    expect(script, contains('github_news.exe'));
    expect(script, contains('flutter_windows.dll'));
    expect(script, contains('data\\app.so'));
    expect(script, contains('data\\flutter_assets'));
    expect(script, contains('MainWindowHandle'));
    expect(script, contains('TimeoutSeconds'));
  });

  test('pixel golden suites are pinned to the Windows baseline platform', () {
    for (final path in ['test/shared/widgets/golden_test.dart', 'test/shared/widgets/main_screens_golden_test.dart']) {
      final source = File(path).readAsStringSync();
      expect(source, contains("import 'dart:io';"), reason: path);
      expect(source, contains('skip: !Platform.isWindows'), reason: path);
    }
  });
}
