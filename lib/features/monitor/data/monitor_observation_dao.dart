import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/monitor_observation.dart';

const int monitorObservationMaxPoints = 90;

/* 观测历史读取结果。corrupted 表示存储读取失败(而非历史为空),
 * 调用方此时不得写回,否则会用单条新观测覆盖原有完整历史。 */
class ObservationReadResult {
  const ObservationReadResult({required this.points, required this.corrupted});

  final List<MonitorObservation> points;
  final bool corrupted;
}

class MonitorObservationDao {
  MonitorObservationDao(this._cache);

  final JsonSnapshotCacheDao _cache;

  Future<ObservationReadResult> readWithStatus(String repoFullName) async {
    final key = _cacheKey(repoFullName);
    try {
      final payload = await _cache.read(key);
      if (payload == null) {
        return const ObservationReadResult(points: [], corrupted: false);
      }
      final points = GitHubJson.list(payload['points']).map(_fromJson).toList(growable: false)..sort((a, b) => a.observedAt.compareTo(b.observedAt));
      return ObservationReadResult(points: points, corrupted: false);
    } on FormatException catch (_) {
      // payload 自身损坏且不可恢复:清除后允许重新积累观测。
      await _discardCorrupt(key);
      return const ObservationReadResult(points: [], corrupted: false);
    } on AppException catch (e) {
      if (e.cause is FormatException) {
        await _discardCorrupt(key);
        return const ObservationReadResult(points: [], corrupted: false);
      }
      AppLogger.warn('monitorObservation.readFailed', meta: {'op': 'read'});
      return const ObservationReadResult(points: [], corrupted: true);
    } catch (_) {
      AppLogger.warn('monitorObservation.readFailed', meta: {'op': 'read'});
      return const ObservationReadResult(points: [], corrupted: true);
    }
  }

  Future<void> _discardCorrupt(String key) async {
    try {
      await _cache.delete(key);
    } catch (_) {
      AppLogger.warn('monitorObservation.deleteFailed', meta: {'op': 'delete'});
    }
  }

  Future<List<MonitorObservation>> read(String repoFullName) async {
    return (await readWithStatus(repoFullName)).points;
  }

  Future<void> record(MonitorObservation observation) async {
    final status = await readWithStatus(observation.repoFullName);
    if (status.corrupted) {
      // 读取失败时保留原 payload,下轮重试;绝不能用空历史覆盖写回。
      AppLogger.warn('monitorObservation.skipRecord', meta: {'reason': 'readFailed'});
      return;
    }
    final points = status.points;
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
      'observedAt': observation.observedAt.toUtc().toIso8601String(),
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
