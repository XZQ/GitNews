import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../domain/monitor_observation.dart';

const int monitorObservationMaxPoints = 90;

class MonitorObservationDao {
  MonitorObservationDao(this._cache);

  final JsonSnapshotCacheDao _cache;

  Future<List<MonitorObservation>> read(String repoFullName) async {
    final key = _cacheKey(repoFullName);
    try {
      final payload = await _cache.read(key);
      if (payload == null) {
        return const [];
      }
      final points = GitHubJson.list(payload['points']).map(_fromJson).toList(growable: false)..sort((a, b) => a.observedAt.compareTo(b.observedAt));
      return points;
    } catch (_) {
      try {
        await _cache.delete(key);
      } catch (_) {
        // A corrupt observation must not block live repository data.
      }
      return const [];
    }
  }

  Future<void> record(MonitorObservation observation) async {
    final points = await read(observation.repoFullName);
    final byDay = {for (final point in points) point.localDayKey: point, observation.localDayKey: observation};
    final sorted = byDay.values.toList()..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    final bounded = sorted.length <= monitorObservationMaxPoints ? sorted : sorted.sublist(sorted.length - monitorObservationMaxPoints);
    await _cache.upsert(
      key: _cacheKey(observation.repoFullName),
      payload: {'repoFullName': observation.repoFullName, 'points': bounded.map(_toJson).toList(growable: false)},
      now: observation.observedAt,
    );
  }

  Future<MonitorObservation?> latestBefore({required String repoFullName, required DateTime observedAt}) async {
    final targetDay = _localDayKey(observedAt);
    final points = await read(repoFullName);
    for (final point in points.reversed) {
      if (point.localDayKey != targetDay && point.observedAt.isBefore(observedAt)) {
        return point;
      }
    }
    return null;
  }

  String _cacheKey(String repoFullName) {
    return 'monitor_observation:v1:${repoFullName.toLowerCase()}';
  }

  Map<String, Object?> _toJson(MonitorObservation observation) {
    return {
      'repoFullName': observation.repoFullName,
      'stars': observation.stars,
      'forks': observation.forks,
      'openIssues': observation.openIssues,
      'observedAt': observation.observedAt.toUtc().toIso8601String()
    };
  }

  MonitorObservation _fromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return MonitorObservation(
      repoFullName: GitHubJson.string(json['repoFullName']),
      stars: GitHubJson.intValue(json['stars']),
      forks: GitHubJson.intValue(json['forks']),
      openIssues: GitHubJson.intValue(json['openIssues']),
      observedAt: DateTime.parse(GitHubJson.string(json['observedAt'])).toLocal(),
    );
  }

  String _localDayKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
