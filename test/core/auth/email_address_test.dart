import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/email_address.dart';

void main() {
  test('masks email identifiers', () {
    expect(maskEmailAddress('developer@example.com'), 'de***@example.com');
    expect(maskEmailAddress('a@example.com'), 'a***@example.com');
    expect(maskEmailAddress('invalid'), isEmpty);
  });
}
