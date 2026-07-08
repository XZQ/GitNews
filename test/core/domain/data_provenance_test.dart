import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_provenance.dart';

void main() {
  test('5 态均可经 .name <-> fromName 往返', () {
    for (final provenance in DataProvenance.values) {
      expect(DataProvenance.fromName(provenance.name), provenance);
    }
  });

  test('fromName 未知值兜底为 seed', () {
    expect(DataProvenance.fromName('observed'), DataProvenance.seed);
    expect(DataProvenance.fromName('localFallback'), DataProvenance.seed);
    expect(DataProvenance.fromName(null), DataProvenance.seed);
    expect(DataProvenance.fromName(''), DataProvenance.seed);
  });

  test('labelKey 覆盖全部 5 态', () {
    for (final provenance in DataProvenance.values) {
      expect(provenance.labelKey, startsWith('provenance.'));
      expect(provenance.labelKey, endsWith('.full'));
    }
  });
}
