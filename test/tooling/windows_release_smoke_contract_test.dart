import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('artifact verification rejects an empty native asset manifest', () async {
    final parent = Directory('build/smoke-contract-tests')..createSync(recursive: true);
    final bundle = parent.createTempSync('bundle-');
    addTearDown(() => bundle.deleteSync(recursive: true));
    for (final name in ['github_news.exe', 'flutter_windows.dll', 'sqlite3.dll', 'data/app.so']) {
      final file = File('${bundle.path}/$name');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('artifact fixture');
    }
    final manifest = File('${bundle.path}/data/flutter_assets/NativeAssetsManifest.json');
    manifest.parent.createSync(recursive: true);
    manifest.writeAsStringSync(jsonEncode({'native-assets': <String, Object?>{}}));
    final arguments = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'tools/windows_release_smoke.ps1', '-ReleaseDir', bundle.path, '-ArtifactsOnly'];
    final missing = await Process.run('powershell', arguments);
    expect(missing.exitCode, 1);
    expect(missing.stdout, contains('SQLite native asset binding is missing'));

    manifest.writeAsStringSync(
      jsonEncode({
        'native-assets': {
          'windows_x64': {
            'package:sqlite3/src/ffi/libsqlite3.g.dart': ['absolute', 'sqlite3.dll'],
          },
        },
      }),
    );
    final valid = await Process.run('powershell', arguments);
    expect(valid.exitCode, 0, reason: '${valid.stdout}\n${valid.stderr}');
    expect(valid.stdout, contains('application startup was not tested'));
  }, skip: !Platform.isWindows);

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
