import 'package:dio/dio.dart';

import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'github_monitor_config.dart';
import 'local_monitor_repository.dart';

const Duration monitorRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub REST API 的仓库监控数据仓库。
class GithubMonitorRepository implements MonitorRepository {
  const GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    MonitorRepository fallback = const LocalMonitorRepository(),
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final MonitorRepository _fallback;

  @override
  Future<MonitorDigest> getDigest() async {
    final now = _now();
    final cached = await _readCached();
    if (cached != null &&
        await _cache.isFresh(
          key: githubMonitorCacheKey,
          ttl: monitorRemoteCacheTtl,
          now: now,
        )) {
      return cached;
    }

    try {
      final digest = await _fetchDigest(now);
      await _cache.upsert(
        key: githubMonitorCacheKey,
        payload: _digestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      AppLogger.warn(
        'githubMonitorFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDigest();
    }
  }

  Future<MonitorDigest?> _readCached() async {
    final json = await _cache.read(githubMonitorCacheKey);
    if (json == null) return null;
    try {
      return _digestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubMonitorCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<MonitorDigest> _fetchDigest(DateTime now) async {
    final responses = await Future.wait([
      for (final repo in githubMonitorDefaultRepos) _fetchRepo(repo, now),
    ]);
    final repos = responses.map((item) => item.repo).toList(growable: false);
    final alerts = responses
        .expand((item) => _alertsFor(item, now))
        .take(12)
        .toList(growable: false);
    return MonitorDigest(
      monitoredRepos: repos,
      alerts: alerts,
      stats: MonitorStats(
        monitoredCount: repos.length,
        monitoredDelta: 0,
        unreadAlertCount: alerts.length,
        unreadAlertDelta: 0,
        triggeredTodayCount: alerts
            .where((alert) => alert.time == '刚刚' || alert.time.contains('小时'))
            .length,
        triggeredTodayDelta: 0,
        totalAlertCount: alerts.length,
        totalAlertDelta: 0,
      ),
    );
  }

  Future<_RemoteRepoItem> _fetchRepo(String fullName, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _parseRepo(data, now);
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  _RemoteRepoItem _parseRepo(Map<String, Object?> json, DateTime now) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final pushedAt =
        DateTime.tryParse(GitHubJson.string(json['pushed_at']))?.toUtc();
    final stars = GitHubJson.intValue(json['stargazers_count']);
    final forks = GitHubJson.intValue(json['forks_count']);
    final openIssues = GitHubJson.intValue(json['open_issues_count']);
    return _RemoteRepoItem(
      repo: RepoEntity(
        fullName: fullName,
        description:
            GitHubJson.nullableString(json['description']) ?? 'No description',
        language: language,
        starCount: stars,
        starDelta: _activityScore(
          stars: stars,
          forks: forks,
          openIssues: openIssues,
          pushedAt: pushedAt,
          now: now,
        ),
        forkCount: forks,
        accentArgb: GitHubApiSupport.languageColor(language),
        valueProvenance: DataProvenance.observed,
        trendProvenance: DataProvenance.estimated,
        trend: _repoTrend(stars),
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }

  List<AlertEntity> _alertsFor(_RemoteRepoItem item, DateTime now) {
    final alerts = <AlertEntity>[
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Star 总量',
        value: _compactNumber(item.repo.starCount),
        time: _relativeTime(item.pushedAt, now),
        severity: AlertSeverity.success,
      ),
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Open Issues',
        value: item.openIssues.toString(),
        time: _relativeTime(item.pushedAt, now),
        severity:
            item.openIssues > 500 ? AlertSeverity.warning : AlertSeverity.info,
      ),
    ];
    return alerts;
  }

  int _activityScore({
    required int stars,
    required int forks,
    required int openIssues,
    required DateTime? pushedAt,
    required DateTime now,
  }) {
    final pushedBoost = pushedAt == null
        ? 1
        : (30 - now.toUtc().difference(pushedAt).inDays).clamp(1, 30);
    return ((stars / 180) + (forks / 40) + (openIssues / 12) + pushedBoost)
        .round()
        .clamp(1, 9999);
  }

  List<double> _repoTrend(int stars) {
    final base = stars / 160;
    return List<double>.generate(
      7,
      (index) => (base * (0.72 + index * 0.06)).roundToDouble(),
    );
  }

  String _relativeTime(DateTime? date, DateTime now) {
    if (date == null) return '未知';
    final diff = now.toUtc().difference(date.toUtc());
    if (diff.inMinutes < 10) return '刚刚';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  Map<String, Object?> _digestToJson(MonitorDigest digest) {
    return {
      'repos': digest.monitoredRepos.map(_repoToJson).toList(),
      'alerts': digest.alerts.map(_alertToJson).toList(),
      'stats': _statsToJson(digest.stats),
    };
  }

  MonitorDigest _digestFromJson(Map<String, Object?> json) {
    return MonitorDigest(
      monitoredRepos:
          GitHubJson.list(json['repos']).map(_repoFromJson).toList(),
      alerts: GitHubJson.list(json['alerts']).map(_alertFromJson).toList(),
      stats: _statsFromJson(GitHubJson.map(json['stats'])),
    );
  }

  Map<String, Object?> _repoToJson(RepoEntity repo) {
    return {
      'fullName': repo.fullName,
      'description': repo.description,
      'language': repo.language,
      'starCount': repo.starCount,
      'starDelta': repo.starDelta,
      'forkCount': repo.forkCount,
      'accentArgb': repo.accentArgb,
      'trend': repo.trend,
    };
  }

  RepoEntity _repoFromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return RepoEntity(
      fullName: GitHubJson.string(json['fullName']),
      description: GitHubJson.string(json['description']),
      language: GitHubJson.string(json['language']),
      starCount: GitHubJson.intValue(json['starCount']),
      starDelta: GitHubJson.intValue(json['starDelta']),
      forkCount: GitHubJson.intValue(json['forkCount']),
      accentArgb: GitHubJson.intValue(json['accentArgb']),
      valueProvenance: DataProvenance.observed,
      trendProvenance: DataProvenance.estimated,
      trend:
          json['trend'] == null ? null : GitHubJson.doubleList(json['trend']),
    );
  }

  Map<String, Object?> _alertToJson(AlertEntity alert) {
    return {
      'repoFullName': alert.repoFullName,
      'metric': alert.metric,
      'value': alert.value,
      'time': alert.time,
      'severity': alert.severity.name,
    };
  }

  AlertEntity _alertFromJson(Object? raw) {
    final json = GitHubJson.map(raw);
    return AlertEntity(
      repoFullName: GitHubJson.string(json['repoFullName']),
      metric: GitHubJson.string(json['metric']),
      value: GitHubJson.string(json['value']),
      time: GitHubJson.string(json['time']),
      severity: AlertSeverity.values.firstWhere(
        (severity) => severity.name == GitHubJson.string(json['severity']),
        orElse: () => AlertSeverity.info,
      ),
    );
  }

  Map<String, Object?> _statsToJson(MonitorStats stats) {
    return {
      'monitoredCount': stats.monitoredCount,
      'monitoredDelta': stats.monitoredDelta,
      'unreadAlertCount': stats.unreadAlertCount,
      'unreadAlertDelta': stats.unreadAlertDelta,
      'triggeredTodayCount': stats.triggeredTodayCount,
      'triggeredTodayDelta': stats.triggeredTodayDelta,
      'totalAlertCount': stats.totalAlertCount,
      'totalAlertDelta': stats.totalAlertDelta,
    };
  }

  MonitorStats _statsFromJson(Map<String, Object?> json) {
    return MonitorStats(
      monitoredCount: GitHubJson.intValue(json['monitoredCount']),
      monitoredDelta: GitHubJson.intValue(json['monitoredDelta']),
      unreadAlertCount: GitHubJson.intValue(json['unreadAlertCount']),
      unreadAlertDelta: GitHubJson.intValue(json['unreadAlertDelta']),
      triggeredTodayCount: GitHubJson.intValue(json['triggeredTodayCount']),
      triggeredTodayDelta: GitHubJson.intValue(json['triggeredTodayDelta']),
      totalAlertCount: GitHubJson.intValue(json['totalAlertCount']),
      totalAlertDelta: GitHubJson.intValue(json['totalAlertDelta']),
    );
  }
}

class _RemoteRepoItem {
  const _RemoteRepoItem({
    required this.repo,
    required this.openIssues,
    required this.pushedAt,
  });

  final RepoEntity repo;
  final int openIssues;
  final DateTime? pushedAt;
}
