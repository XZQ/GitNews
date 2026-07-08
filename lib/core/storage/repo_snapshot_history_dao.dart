import '../domain/data_provenance.dart';
import '../github/github_api_support.dart';
import 'json_snapshot_cache_dao.dart';

const int repoSnapshotHistoryMaxPoints = 30;

class RepoSnapshotHistoryDao {
  RepoSnapshotHistoryDao(this._cache);

  final JsonSnapshotCacheDao _cache;

  Future<void> record({
    required String fullName,
    required int stars,
    required int forks,
    required DateTime capturedAt,
  }) async {
    final key = _cacheKey(fullName);
    final payload = await _cache.read(key) ?? const <String, Object?>{};
    final points = _pointsFromPayload(payload);
    final dayKey = GitHubApiSupport.formatDate(capturedAt.toUtc());
    final nextPoint = RepoSnapshotPoint(
      day: dayKey,
      stars: stars,
      forks: forks,
      capturedAt: capturedAt.toUtc(),
    );
    final byDay = {
      for (final point in points) point.day: point,
      dayKey: nextPoint,
    };
    final next = byDay.values.toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final bounded = next.length <= repoSnapshotHistoryMaxPoints
        ? next
        : next.sublist(next.length - repoSnapshotHistoryMaxPoints);
    await _cache.upsert(
      key: key,
      payload: {
        'fullName': fullName,
        'points': bounded.map((point) => point.toJson()).toList(),
      },
      now: capturedAt,
    );
  }

  Future<RepoTrendSnapshot?> starTrend(String fullName) async {
    final points = await _pointsFor(fullName);
    if (points.length < 2) return null;
    return RepoTrendSnapshot(
      values: [for (final point in points) point.stars.toDouble()],
      provenance: DataProvenance.live,
    );
  }

  Future<RepoTrendSnapshot?> forkTrend(String fullName) async {
    final points = await _pointsFor(fullName);
    if (points.length < 2) return null;
    return RepoTrendSnapshot(
      values: [for (final point in points) point.forks.toDouble()],
      provenance: DataProvenance.live,
    );
  }

  Future<List<RepoSnapshotPoint>> _pointsFor(String fullName) async {
    final payload = await _cache.read(_cacheKey(fullName));
    if (payload == null) return const [];
    return _pointsFromPayload(payload);
  }

  List<RepoSnapshotPoint> _pointsFromPayload(Map<String, Object?> payload) {
    final raw = payload['points'];
    if (raw == null) return const [];
    return GitHubJson.list(raw)
        .map(RepoSnapshotPoint.fromJson)
        .toList(growable: false)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  }

  String _cacheKey(String fullName) {
    return 'repo_snapshot_history:v1:${fullName.toLowerCase()}';
  }
}

class RepoTrendSnapshot {
  const RepoTrendSnapshot({
    required this.values,
    required this.provenance,
  });

  final List<double> values;
  final DataProvenance provenance;
}

class RepoSnapshotPoint {
  const RepoSnapshotPoint({
    required this.day,
    required this.stars,
    required this.forks,
    required this.capturedAt,
  });

  final String day;
  final int stars;
  final int forks;
  final DateTime capturedAt;

  Map<String, Object?> toJson() {
    return {
      'day': day,
      'stars': stars,
      'forks': forks,
      'capturedAt': capturedAt.toIso8601String(),
    };
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
