import 'repo_entity.dart';

/// Net Star change for a fixed cohort on shared UTC observation dates.
/// Missing days are never interpolated or treated as consecutive samples.
class ObservedRepoGrowth {
  const ObservedRepoGrowth({required this.dates, required this.values, required this.sampleCount, required this.totalCount});

  factory ObservedRepoGrowth.fromRepos(Iterable<RepoEntity> repos, {int days = 30, DateTime? now}) {
    final unique = {for (final repo in repos) repo.fullName.toLowerCase(): repo};
    final end = utcDay(now ?? DateTime.now());
    final start = end.subtract(Duration(days: days));
    final samples = <Map<DateTime, double>>[];
    for (final repo in unique.values) {
      if (!repo.hasObservedTrend) continue;
      final points = <DateTime, double>{};
      for (var index = 0; index < repo.trendDates.length; index++) {
        final date = utcDay(repo.trendDates[index]);
        final value = repo.trend![index];
        if (!date.isBefore(start) && !date.isAfter(end) && value.isFinite) {
          points[date] = value;
        }
      }
      if (points.length >= 2) samples.add(points);
    }
    var common = samples.isEmpty ? <DateTime>{} : samples.first.keys.toSet();
    for (final points in samples.skip(1)) {
      common = common.intersection(points.keys.toSet());
    }
    if (common.length < 2) {
      return ObservedRepoGrowth(dates: const [], values: const [], sampleCount: 0, totalCount: unique.length);
    }
    final dates = common.toList()..sort();
    final values = [for (final date in dates) samples.fold<double>(0, (sum, points) => sum + points[date]! - points[dates.first]!)];
    return ObservedRepoGrowth(dates: dates, values: values, sampleCount: samples.length, totalCount: unique.length);
  }

  final List<DateTime> dates;
  final List<double> values;
  final int sampleCount;
  final int totalCount;
  bool get isEmpty => dates.length < 2;
  int? get netChange => isEmpty ? null : values.last.round();

  static DateTime utcDay(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
