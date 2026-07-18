import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/phone_number.dart';

void main() {
  test('normalizes mainland mobile numbers to E.164', () {
    expect(normalizeMainlandPhoneNumber('138 1234 5678'), '+8613812345678');
    expect(normalizeMainlandPhoneNumber('+86 138-1234-5678'), '+8613812345678');
    expect(normalizeMainlandPhoneNumber('0086 13812345678'), '+8613812345678');
  });

  test('rejects invalid mainland mobile numbers', () {
    expect(normalizeMainlandPhoneNumber('12812345678'), isNull);
    expect(normalizeMainlandPhoneNumber('1381234567'), isNull);
    expect(normalizeMainlandPhoneNumber('not-a-phone'), isNull);
  });

  test('masks phone and email identifiers', () {
    expect(maskMainlandPhoneNumber('+8613812345678'), '+86 138****5678');
    expect(maskEmailAddress('developer@example.com'), 'de***@example.com');
  });
}
