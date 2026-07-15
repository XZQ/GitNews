import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/preferences/server_connection_controller.dart';

void main() {
  test('normalizes an absolute server URL', () {
    expect(
      normalizeServerBaseUrl(' https://sync.example.com/api/// '),
      'https://sync.example.com/api',
    );
  });

  test('rejects relative and non-http server URLs', () {
    expect(() => normalizeServerBaseUrl('/api'), throwsFormatException);
    expect(
      () => normalizeServerBaseUrl('file:///tmp/server'),
      throwsFormatException,
    );
  });
}
