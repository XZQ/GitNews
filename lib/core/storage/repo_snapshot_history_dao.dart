import '../domain/data_freshness.dart';
import '../github/github_api_support.dart';
import 'json_snapshot_cache_dao.dart';

const int repoSnapshotHistoryMaxPoints = 30;

class RepoSnapshotHistoryDao {
  RepoSnapshotHistoryDao(this._cache);

  final JsonSnapshotCacheDao _cache;

  // 同仓库的 record 串行执行:trending/monitor/repo_detail 可能并发
  // 记录同一仓库,读-改-写不串行会互相覆盖观测点。
  final Map<String, Future<void>> _recordLocks = {};

  Future<void> record({required String fullName, required int stars, required int forks, required DateTime capturedAt}) {
    final key = _cacheKey(fullName);
    final previous = _recordLocks[key] ?? Future<void>.value();
    final next = previous.then((_) => _record(key, fullName: fullName, stars: stars, forks: forks, capturedAt: capturedAt));
    // 链上吞错保持后续记录可用;调用方仍从 next 拿到真实错误。
    _recordLocks[key] = next.catchError((Object _) {});
    return next;
  }

  Future<void> _record(String key, {required String fullName, required int stars, required int forks, required DateTime capturedAt}) async {
    final payload = await _cache.read(key) ?? const <String, Object?>{};
    final points = _pointsFromPayload(payload);
    final dayKey = GitHubApiSupport.formatDate(capturedAt.toUtc());
    final nextPoint = RepoSnapshotPoint(day: dayKey, stars: stars, forks: forks, capturedAt: capturedAt.toUtc());
    final byDay = {for (final point in points) point.day: point, dayKey: nextPoint};
    final next = byDay.values.toList()..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final bounded = next.length <= repoSnapshotHistoryMaxPoints ? next : next.sublist(next.length - repoSnapshotHistoryMaxPoints);
    await _cache.upsert(key: key, payload: {'fullName': fullName, 'points': bounded.map((point) => point.toJson()).toList()}, now: capturedAt);
  }

  Future<RepoTrendSnapshot?> starTrend(String fullName) async {
    final points = await _pointsFor(fullName);
    if (points.length < 2) {
      return null;
    }
    return RepoTrendSnapshot(values: [for (final point in points) point.stars.toDouble()], dates: [for (final point in points) DateTime.parse('${point.day}T00:00:00Z')], basis: MetricBasis.observed);
  }

  Future<RepoTrendSnapshot?> forkTrend(String fullName) async {
    final points = await _pointsFor(fullName);
    if (points.length < 2) {
      return null;
    }
    return RepoTrendSnapshot(values: [for (final point in points) point.forks.toDouble()], dates: [for (final point in points) DateTime.parse('${point.day}T00:00:00Z')], basis: MetricBasis.observed);
  }

  Future<List<RepoSnapshotPoint>> _pointsFor(String fullName) async {
    final payload = await _cache.read(_cacheKey(fullName));
    if (payload == null) {
      return const [];
    }
    return _pointsFromPayload(payload);
  }

  List<RepoSnapshotPoint> _pointsFromPayload(Map<String, Object?> payload) {
    final raw = payload['points'];
    if (raw == null) {
      return const [];
    }
    return GitHubJson.list(raw).map(RepoSnapshotPoint.fromJson).toList(growable: false)..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  }

  String _cacheKey(String fullName) {
    return 'repo_snapshot_history:v1:${fullName.toLowerCase()}';
  }
}

class RepoTrendSnapshot {
  const RepoTrendSnapshot({required this.values, required this.dates, required this.basis});

  final List<double> values;
  final List<DateTime> dates;
  final MetricBasis basis;
}

class RepoSnapshotPoint {
  const RepoSnapshotPoint({required this.day, required this.stars, required this.forks, required this.capturedAt});

  final String day;
  final int stars;
  final int forks;
  final DateTime capturedAt;

  Map<String, Object?> toJson() {
    return {'day': day, 'stars': stars, 'forks': forks, 'capturedAt': capturedAt.toIso8601String()};
  }

  static RepoSnapshotPoint fromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return RepoSnapshotPoint(
      day: GitHubJson.string(json['day']),
      stars: GitHubJson.intValue(json['stars']),
      forks: GitHubJson.intValue(json['forks']),
      capturedAt: DateTime.parse(GitHubJson.string(json['capturedAt'])).toUtc(),
    );
  }
}
