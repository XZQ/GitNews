import '../../../core/domain/data_freshness.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';

const int techHotspotHistoryMaxPoints = 30;

class TechHotspotHistoryDao {
  TechHotspotHistoryDao(this._cache);

  final JsonSnapshotCacheDao _cache;

  Future<void> record({required String id, required int heat, required int mentions, required int relatedRepos, required DateTime capturedAt}) async {
    final key = _cacheKey(id);
    final payload = await _cache.read(key) ?? const <String, Object?>{};
    final points = _pointsFromPayload(payload);
    final dayKey = GitHubApiSupport.formatDate(capturedAt.toUtc());
    final nextPoint = TechHotspotHistoryPoint(day: dayKey, heat: heat, mentions: mentions, relatedRepos: relatedRepos, capturedAt: capturedAt.toUtc());
    final byDay = {for (final point in points) point.day: point, dayKey: nextPoint};
    final next = byDay.values.toList()..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final bounded = next.length <= techHotspotHistoryMaxPoints ? next : next.sublist(next.length - techHotspotHistoryMaxPoints);
    await _cache.upsert(key: key, payload: {'id': id, 'points': bounded.map((point) => point.toJson()).toList()}, now: capturedAt);
  }

  Future<TechHotspotTrendSnapshot?> trend(String id) async {
    final payload = await _cache.read(_cacheKey(id));
    if (payload == null) {
      return null;
    }
    final points = _pointsFromPayload(payload);
    if (points.length < 2) {
      return null;
    }
    final first = points.first;
    final last = points.last;
    return TechHotspotTrendSnapshot(heatValues: [for (final point in points) point.heat.toDouble()], growth: _growthPercent(first.relatedRepos, last.relatedRepos), basis: MetricBasis.observed);
  }

  List<TechHotspotHistoryPoint> _pointsFromPayload(Map<String, Object?> payload) {
    final raw = payload['points'];
    if (raw == null) {
      return const [];
    }
    return GitHubJson.list(raw).map(TechHotspotHistoryPoint.fromJson).toList(growable: false)..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  }

  double _growthPercent(int first, int last) {
    if (first <= 0) {
      return 0;
    }
    return ((last - first) / first * 100).clamp(-99, 999).toDouble();
  }

  String _cacheKey(String id) {
    return 'tech_hotspot_history:v1:${id.toLowerCase()}';
  }
}

class TechHotspotTrendSnapshot {
  const TechHotspotTrendSnapshot({required this.heatValues, required this.growth, required this.basis});

  final List<double> heatValues;
  final double growth;
  final MetricBasis basis;
}

class TechHotspotHistoryPoint {
  const TechHotspotHistoryPoint({required this.day, required this.heat, required this.mentions, required this.relatedRepos, required this.capturedAt});

  final String day;
  final int heat;
  final int mentions;
  final int relatedRepos;
  final DateTime capturedAt;

  Map<String, Object?> toJson() {
    return {'day': day, 'heat': heat, 'mentions': mentions, 'relatedRepos': relatedRepos, 'capturedAt': capturedAt.toIso8601String()};
  }

  static TechHotspotHistoryPoint fromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return TechHotspotHistoryPoint(
      day: GitHubJson.string(json['day']),
      heat: GitHubJson.intValue(json['heat']),
      mentions: GitHubJson.intValue(json['mentions']),
      relatedRepos: GitHubJson.intValue(json['relatedRepos']),
      capturedAt: DateTime.parse(GitHubJson.string(json['capturedAt'])).toUtc(),
    );
  }
}
