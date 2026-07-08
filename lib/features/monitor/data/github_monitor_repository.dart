import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/network/parallel.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'github_monitor_cache_codec.dart';
import 'github_monitor_config.dart';
import 'github_monitor_remote_repo_item.dart';
import 'local_monitor_repository.dart';

const Duration monitorRemoteCacheTtl = CacheTtlConfig.monitor;

/* 
*基于 GitHub REST API 的仓库监控数据仓库。
*/
class GithubMonitorRepository implements MonitorRepository {
  const GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    RepoSnapshotHistoryDao? snapshotHistory,
    String? token,
    DateTime Function()? now,
    MonitorRepository fallback = const LocalMonitorRepository(),
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
    this.repos = githubMonitorDefaultRepos,
    this.cacheKey = githubMonitorCacheKey,
  })  : _dio = dio,
        _cache = cache,
        _snapshotHistory = snapshotHistory,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final RepoSnapshotHistoryDao? _snapshotHistory;
  final String? _token;
  final DateTime Function() _now;
  final MonitorRepository _fallback;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;
  final List<String> repos;
  final String cacheKey;

  @override
  Future<MonitorDigest> getDigest() async {
    if (_isRateLimited?.call() ?? false) {
      final cached = await _readCached();
      return cached ?? _fallback.getDigest();
    }
    final now = _now();
    final cached = await _readCached();
    if (cached != null &&
        await _cache.isFresh(
          key: cacheKey,
          ttl: monitorRemoteCacheTtl,
          now: now,
        )) {
      return cached;
    }

    try {
      final digest = await _fetchDigest(now);
      await _cache.upsert(
        key: cacheKey,
        payload: monitorDigestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      _maybeReportRateLimit(e);
      AppLogger.warn(
        'githubMonitorFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDigest();
    }
  }

  void _maybeReportRateLimit(Object error) {
    if (error is AppException &&
        error.kind == AppExceptionKind.rateLimit &&
        _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<MonitorDigest?> _readCached() async {
    final json = await _cache.read(cacheKey);
    if (json == null) return null;
    try {
      return monitorDigestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubMonitorCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<MonitorDigest> _fetchDigest(DateTime now) async {
    final responses = await gatherAll<GithubMonitorRemoteRepoItem>([
      for (final repo in repos) _fetchRepo(repo, now),
    ], tag: 'githubMonitorFetch');
    final repoEntities =
        responses.map((item) => item.repo).toList(growable: false);
    final alerts = responses
        .expand((item) => _alertsFor(item, now))
        .take(12)
        .toList(growable: false);
    return MonitorDigest(
      monitoredRepos: repoEntities,
      alerts: alerts,
      stats: MonitorStats(
        monitoredCount: repoEntities.length,
        monitoredDelta: 0,
        unreadAlertCount: alerts.length,
        unreadAlertDelta: 0,
        triggeredTodayCount:
            responses.where((item) => _isToday(item.pushedAt, now)).length,
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
        ApiEndpointsConfig.githubRepoPath(fullName),
        options: Options(headers: GitHubApiSupport.headers(token: _token)),
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
          starDelta: _observedDelta(
            starTrend.values,
            fallback: item.repo.starDelta,
          ),
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

  int _observedDelta(List<double> values, {required int fallback}) {
    if (values.length < 2) return fallback;
    final delta = values.last - values.first;
    return delta.round().clamp(0, 999999);
  }

  bool _isToday(DateTime? value, DateTime now) {
    final v = value?.toLocal();
    if (v == null) return false;
    return v.year == now.year && v.month == now.month && v.day == now.day;
  }

  GithubMonitorRemoteRepoItem _parseRepo(
    Map<String, Object?> json,
    DateTime now,
  ) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final pushedAt = DateTime.tryParse(
      GitHubJson.string(json['pushed_at']),
    )?.toUtc();
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
        valueProvenance: DataProvenance.live,
        trendProvenance: DataProvenance.estimated,
        trend: githubMonitorEstimatedRepoTrend(stars),
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }

  List<AlertEntity> _alertsFor(GithubMonitorRemoteRepoItem item, DateTime now) {
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
}
