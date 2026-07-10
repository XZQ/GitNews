import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/data_provenance.dart';
import 'package:github_news/core/domain/repo_entity.dart';

void main() {
  test('DataResult maps data without losing freshness', () {
    const source = DataResult<int>(
      data: 2,
      freshness: DataFreshness.staleCache,
    );

    final mapped = source.map((value) => '$value');

    expect(mapped.data, '2');
    expect(mapped.freshness, DataFreshness.staleCache);
  });

  test('unknown enum names use safe seed defaults', () {
    expect(DataFreshness.fromName('unknown'), DataFreshness.seed);
    expect(MetricBasis.fromName('unknown'), MetricBasis.seed);
  });

  test('all trust enums round-trip through their names', () {
    for (final freshness in DataFreshness.values) {
      expect(DataFreshness.fromName(freshness.name), freshness);
    }
    for (final basis in MetricBasis.values) {
      expect(MetricBasis.fromName(basis.name), basis);
    }
  });

  test('legacy repo provenance maps to metric basis during migration', () {
    const repo = RepoEntity(
      fullName: 'owner/repo',
      description: 'desc',
      language: 'Dart',
      starCount: 10,
      starDelta: 2,
      forkCount: 1,
      accentArgb: 0xFF000000,
      valueProvenance: DataProvenance.live,
      trendProvenance: DataProvenance.estimated,
    );

    expect(repo.valueBasis, MetricBasis.observed);
    expect(repo.trendBasis, MetricBasis.estimated);
  });
}
