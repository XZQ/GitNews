import 'package:dio/dio.dart';

import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'github_monitor_config.dart';
import 'github_monitor_remote_repo_item.dart';
import 'local_monitor_repository.dart';

const Duration monitorRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub REST API 的仓库监控数据仓库。
class GithubMonitorRepository implements MonitorRepository {
  const GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    RepoSnapshotHistoryDao? snapshotHistory,
    String? token,
    DateTime Function()? now,
    MonitorRepository fallback = const LocalMonitorRepository(),
  })  : _dio = dio,
        _cache = cache,
        _snapshotHistory = snapshotHistory,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final RepoSnapshotHistoryDao? _snapshotHistory;
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

  Future<GithubMonitorRemoteRepoItem> _fetchRepo(
    String fullName,
    DateTime now,
  ) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      final item = _parseRepo(data, now);
      final history = _snapshotHistory;
      if (history == null) return item;
      await history.record(
        fullName: item.repo.fullName,
        stars: item.repo.starCount,
        forks: item.repo.forkCount,
        capturedAt: now,
      );
      final starTrend = await history.starTrend(item.repo.fullName);
      if (starTrend == null) return item;
      return item.copyWith(
        repo: item.repo.copyWith(
          trend: starTrend.values,
          trendProvenance: starTrend.provenance,
        ),
      );
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  GithubMonitorRemoteRepoItem _parseRepo(
    Map<String, Object?> json,
    DateTime now,
  ) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final pushedAt =
        DateTime.tryParse(GitHubJson.string(json['pushed_at']))?.toUtc();
    final stars = GitHubJson.intValue(json['stargazers_count']);
    final forks = GitHubJson.intValue(json['forks_count']);
    final openIssues = GitHubJson.intValue(json['open_issues_count']);
    return GithubMonitorRemoteRepoItem(
      repo: RepoEntity(
        fullName: fullName,
        description:
            GitHubJson.nullableString(json['description']) ?? 'No description',
        language: language,
        starCount: stars,
        starDelta: githubMonitorActivityScore(
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
        trend: githubMonitorEstimatedRepoTrend(stars),
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }

  List<AlertEntity> _alertsFor(
    GithubMonitorRemoteRepoItem item,
    DateTime now,
  ) {
    final alerts = <AlertEntity>[
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Star 总量',
        value: githubMonitorCompactNumber(item.repo.starCount),
        time: githubMonitorRelativeTime(item.pushedAt, now),
        severity: AlertSeverity.success,
      ),
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Open Issues',
        value: item.openIssues.toString(),
        time: githubMonitorRelativeTime(item.pushedAt, now),
        severity:
            item.openIssues > 500 ? AlertSeverity.warning : AlertSeverity.info,
      ),
    ];
    return alerts;
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
      'valueProvenance': repo.valueProvenance.name,
      'trendProvenance': repo.trendProvenance.name,
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
      valueProvenance: DataProvenance.fromName(
        GitHubJson.nullableString(json['valueProvenance']),
      ),
      trendProvenance: DataProvenance.fromName(
        GitHubJson.nullableString(json['trendProvenance']),
      ),
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
