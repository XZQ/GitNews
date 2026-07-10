import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/network/parallel.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/monitor_observation.dart';
import '../domain/monitor_repository.dart';
import '../domain/monitor_rule.dart';
import '../domain/monitor_rule_evaluator.dart';
import 'github_monitor_cache_codec.dart';
import 'github_monitor_config.dart';
import 'github_monitor_remote_repo_item.dart';
import 'local_monitor_repository.dart';
import 'monitor_alert_event_dao.dart';
import 'monitor_observation_dao.dart';

const Duration monitorRemoteCacheTtl = CacheTtlConfig.monitor;

class GithubMonitorRepository implements MonitorRepository {
  const GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    required MonitorObservationDao observationDao,
    required MonitorAlertEventDao alertDao,
    RepoSnapshotHistoryDao? snapshotHistory,
    MonitorRuleEvaluator evaluator = const MonitorRuleEvaluator(),
    Set<String> enabledRuleIds = MonitorRuleIds.all,
    String? token,
    DateTime Function()? now,
    MonitorRepository fallback = const LocalMonitorRepository(),
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
    this.repos = githubMonitorDefaultRepos,
    this.cacheKey = githubMonitorCacheKey,
  })  : _dio = dio,
        _cache = cache,
        _observationDao = observationDao,
        _alertDao = alertDao,
        _snapshotHistory = snapshotHistory,
        _evaluator = evaluator,
        _enabledRuleIds = enabledRuleIds,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final MonitorObservationDao _observationDao;
  final MonitorAlertEventDao _alertDao;
  final RepoSnapshotHistoryDao? _snapshotHistory;
  final MonitorRuleEvaluator _evaluator;
  final Set<String> _enabledRuleIds;
  final String? _token;
  final DateTime Function() _now;
  final MonitorRepository _fallback;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;
  final List<String> repos;
  final String cacheKey;

  @override
  Future<DataResult<MonitorDigest>> getDigest({bool force = false}) async {
    final now = _now();
    final cached = await _readCached();
    final fresh = cached != null && await _isFresh(now);

    if (!force && fresh) {
      return DataResult(
        data: await _withStoredAlerts(cached, now),
        freshness: DataFreshness.freshCache,
      );
    }
    if (_isRateLimited?.call() ?? false) {
      return _fallbackResult(cached, now);
    }
    if (force) {
      await _safeDeleteCache();
    }

    try {
      final responses = await _fetchRepos(now);
      final digest = _digestFromResponses(responses);
      await _recordObservationsAndAlerts(responses, now);
      await _cache.upsert(
        key: cacheKey,
        payload: monitorDigestToJson(digest),
        now: now,
      );
      return DataResult(
        data: await _withStoredAlerts(digest, now),
        freshness: DataFreshness.live,
      );
    } catch (error) {
      _maybeReportRateLimit(error);
      AppLogger.warn(
        'githubMonitorFallback',
        meta: {'error': error.runtimeType.toString()},
      );
      return _fallbackResult(cached, now);
    }
  }

  Future<DataResult<MonitorDigest>> _fallbackResult(
    MonitorDigest? cached,
    DateTime now,
  ) async {
    if (cached != null) {
      return DataResult(
        data: await _withStoredAlerts(cached, now),
        freshness: DataFreshness.staleCache,
      );
    }
    final fallback = await _fallback.getDigest();
    return DataResult(
      data: await _withStoredAlerts(fallback.data, now),
      freshness: fallback.freshness,
    );
  }

  Future<bool> _isFresh(DateTime now) async {
    try {
      return await _cache.isFresh(
        key: cacheKey,
        ttl: monitorRemoteCacheTtl,
        now: now,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _safeDeleteCache() async {
    try {
      await _cache.delete(cacheKey);
    } catch (_) {
      // The in-memory stale value can still be used if refresh fails.
    }
  }

  void _maybeReportRateLimit(Object error) {
    if (error is AppException && error.kind == AppExceptionKind.rateLimit && _onRateLimited != null) {
      _onRateLimited(error.retryAfterSeconds ?? 60);
    }
  }

  Future<MonitorDigest?> _readCached() async {
    try {
      final json = await _cache.read(cacheKey);
      if (json == null) {
        return null;
      }
      return monitorDigestFromJson(json);
    } catch (error) {
      AppLogger.warn(
        'githubMonitorCacheParse',
        meta: {'error': error.runtimeType.toString()},
      );
      await _safeDeleteCache();
      return null;
    }
  }

  Future<List<GithubMonitorRemoteRepoItem>> _fetchRepos(DateTime now) {
    return gatherAll<GithubMonitorRemoteRepoItem>(
      [for (final repo in repos) _fetchRepo(repo, now)],
      tag: 'githubMonitorFetch',
    );
  }

  MonitorDigest _digestFromResponses(
    List<GithubMonitorRemoteRepoItem> responses,
  ) {
    final repos = responses.map((item) => item.repo).toList(growable: false);
    return MonitorDigest(
      monitoredRepos: repos,
      alerts: const [],
      stats: MonitorStats(
        monitoredCount: repos.length,
        monitoredDelta: 0,
        unreadAlertCount: 0,
        unreadAlertDelta: 0,
        triggeredTodayCount: 0,
        triggeredTodayDelta: 0,
        totalAlertCount: 0,
        totalAlertDelta: 0,
      ),
    );
  }

  Future<void> _recordObservationsAndAlerts(
    List<GithubMonitorRemoteRepoItem> responses,
    DateTime now,
  ) async {
    final events = <MonitorAlertEvent>[];
    for (final item in responses) {
      final current = MonitorObservation(
        repoFullName: item.repo.fullName,
        stars: item.repo.starCount,
        forks: item.repo.forkCount,
        openIssues: item.openIssues,
        observedAt: now,
      );
      final previous = await _observationDao.latestBefore(
        repoFullName: current.repoFullName,
        observedAt: current.observedAt,
      );
      events.addAll(
        _evaluator.evaluate(
          previous: previous,
          current: current,
          enabledRuleIds: _enabledRuleIds,
        ),
      );
      await _observationDao.record(current);
    }
    await _alertDao.upsertAll(events);
  }

  Future<MonitorDigest> _withStoredAlerts(
    MonitorDigest digest,
    DateTime now,
  ) async {
    final stored = await _alertDao.list(includeArchived: true);
    final visible = stored.where((event) => !event.isArchived).toList();
    final alerts = visible.map((event) => _toAlertEntity(event, now)).toList();
    return MonitorDigest(
      monitoredRepos: digest.monitoredRepos,
      alerts: alerts,
      stats: MonitorStats(
        monitoredCount: digest.monitoredRepos.length,
        monitoredDelta: 0,
        unreadAlertCount: visible.where((event) => !event.isRead).length,
        unreadAlertDelta: 0,
        triggeredTodayCount: visible.where((event) => _isToday(event.observedAt, now)).length,
        triggeredTodayDelta: 0,
        totalAlertCount: visible.length,
        totalAlertDelta: 0,
      ),
    );
  }

  AlertEntity _toAlertEntity(MonitorAlertEvent event, DateTime now) {
    final value = switch (event.ruleId) {
      MonitorRuleIds.starDailyRate => '${event.value.toStringAsFixed(1)}%',
      MonitorRuleIds.issueHeatRatio => '${event.value.toStringAsFixed(1)}x',
      _ => '+${event.value.round()}',
    };
    return AlertEntity(
      id: event.id,
      repoFullName: event.repoFullName,
      ruleId: event.ruleId,
      metric: event.ruleId,
      value: value,
      time: githubMonitorRelativeTime(event.observedAt, now),
      severity: event.severity,
      observedAt: event.observedAt,
      readAt: event.readAt,
      archivedAt: event.archivedAt,
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
      return _withSnapshotTrend(item, now);
    } on DioException catch (error) {
      final exception = GitHubApiSupport.toAppException(error, now: _now);
      _maybeReportRateLimit(exception);
      throw exception;
    } on FormatException catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.parse,
        cause: error,
        stack: stack,
      );
    } on TypeError catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.parse,
        cause: error,
        stack: stack,
      );
    }
  }

  Future<GithubMonitorRemoteRepoItem> _withSnapshotTrend(
    GithubMonitorRemoteRepoItem item,
    DateTime now,
  ) async {
    final history = _snapshotHistory;
    if (history == null) {
      return item;
    }
    await history.record(
      fullName: item.repo.fullName,
      stars: item.repo.starCount,
      forks: item.repo.forkCount,
      capturedAt: now,
    );
    final starTrend = await history.starTrend(item.repo.fullName);
    if (starTrend == null) {
      return item;
    }
    return item.copyWith(
      repo: item.repo.copyWith(
        starDelta: _observedDelta(
          starTrend.values,
          fallback: item.repo.starDelta,
        ),
        trend: starTrend.values,
        trendBasis: starTrend.basis,
      ),
    );
  }

  int _observedDelta(List<double> values, {required int fallback}) {
    if (values.length < 2) {
      return fallback;
    }
    return (values.last - values.first).round().clamp(0, 999999);
  }

  bool _isToday(DateTime? value, DateTime now) {
    final local = value?.toLocal();
    final today = now.toLocal();
    return local != null && local.year == today.year && local.month == today.month && local.day == today.day;
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
        description: GitHubJson.nullableString(json['description']) ?? 'No description',
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
        valueBasis: MetricBasis.observed,
        trendBasis: MetricBasis.estimated,
        trend: githubMonitorEstimatedRepoTrend(stars),
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }
}
