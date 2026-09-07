import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/observed_repo_growth.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/github/github_repo_entity_codec.dart';

void main() {
  final now = DateTime.utc(2026, 7, 10);
  test('aligns a fixed cohort by actual dates and excludes unobserved repos', () {
    final growth = ObservedRepoGrowth.fromRepos([
      _repo('a', {1: 100, 3: 120, 8: 160, 10: 150}),
      _repo('b', {1: 200, 8: 230, 10: 240}),
      _repo('new', {10: 9000}),
    ], now: now);
    expect(growth.dates, [DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 8), now]);
    expect(growth.values, [0, 90, 90]);
    expect(growth.sampleCount, 2);
    expect(growth.totalCount, 3);
  });

  test('calendar window does not treat two distant observations as today', () {
    final repo = _repo('a', {1: 100, 8: 120, 10: 110});
    expect(ObservedRepoGrowth.fromRepos([repo], days: 1, now: now).isEmpty, isTrue);
    final week = ObservedRepoGrowth.fromRepos([repo], days: 7, now: now);
    expect(week.dates, [DateTime.utc(2026, 7, 8), now]);
    expect(week.values, [0, -10]);
    expect(week.netChange, -10);
  });

  test('requires two shared dates instead of aligning unrelated positions', () {
    final growth = ObservedRepoGrowth.fromRepos([
      _repo('a', {1: 100, 5: 120}),
      _repo('b', {2: 200, 6: 240}),
    ], now: now);
    expect(growth.isEmpty, isTrue);
    expect(growth.netChange, isNull);
  });

  test('dated history survives cache codec and copyWith; legacy curves stay unavailable', () {
    final json = githubRepoEntityToJson(_repo('a', {1: 100, 10: 120}).copyWith(starDeltaDays: 7));
    final restored = githubRepoEntityFromJson(json).copyWith(description: 'updated');
    expect(restored.trendDates, [DateTime.utc(2026, 7, 1), now]);
    expect(restored.starDeltaDays, 7);
    expect(ObservedRepoGrowth.fromRepos([restored], now: now).netChange, 20);
    json.remove('trendDates');
    expect(ObservedRepoGrowth.fromRepos([githubRepoEntityFromJson(json)], now: now).isEmpty, isTrue);
  });

  test('does not include future, stale or seed samples', () {
    expect(
      ObservedRepoGrowth.fromRepos([
        _repo('a', {1: 10, 2: 20}),
      ], now: DateTime.utc(2026, 9, 1)).isEmpty,
      isTrue,
    );
    expect(
      ObservedRepoGrowth.fromRepos([
        _repo('a', {11: 10, 12: 20}),
      ], now: now).isEmpty,
      isTrue,
    );
    expect(
      ObservedRepoGrowth.fromRepos([
        _repo('a', {1: 10, 2: 20}).copyWith(trendBasis: MetricBasis.seed),
      ], now: now).isEmpty,
      isTrue,
    );
  });
}

RepoEntity _repo(String name, Map<int, double> points) => RepoEntity(
  fullName: 'test/$name',
  description: '',
  language: 'Dart',
  starCount: points.values.last.round(),
  starDelta: 0,
  forkCount: 0,
  accentArgb: 0,
  trendBasis: MetricBasis.observed,
  trend: points.values.toList(),
  trendDates: [for (final day in points.keys) DateTime.utc(2026, 7, day)],
);
