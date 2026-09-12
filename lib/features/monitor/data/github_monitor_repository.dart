import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_check_status.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/monitor_repository.dart';
import '../domain/monitor_rule.dart';
import '../domain/monitor_rule_evaluator.dart';
import 'github_monitor_cache_codec.dart';
import 'github_monitor_config.dart';
import 'github_monitor_remote_repo_item.dart';
import 'monitor_alert_event_dao.dart';
import 'monitor_digest_assembler.dart';
import 'monitor_observation_dao.dart';
import 'monitor_refresh_batch.dart';

const Duration monitorRemoteCacheTtl = CacheTtlConfig.monitor;

class GithubMonitorRepository implements MonitorRepository {
  GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    required MonitorObservationDao observationDao,
    required MonitorAlertEventDao alertDao,
    RepoSnapshotHistoryDao? snapshotHistory,
    MonitorRuleEvaluator evaluator = const MonitorRuleEvaluator(),
    Set<String> enabledRuleIds = MonitorRuleIds.all,
    String? token,
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
    this.repos = githubMonitorDefaultRepos,
    this.cacheKey = githubMonitorCacheKey,
  }) : _dio = dio,
       _cache = cache,
       _assembler = MonitorDigestAssembler(observationDao: observationDao, alertDao: alertDao, evaluator: evaluator, enabledRuleIds: enabledRuleIds),
       _snapshotHistory = snapshotHistory,
       _token = token,
       _now = now ?? DateTime.now,
       _isRateLimited = isRateLimited,
       _onRateLimited = onRateLimited;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final MonitorDigestAssembler _assembler;
  final RepoSnapshotHistoryDao? _snapshotHistory;
  final String? _token;
  final DateTime Function() _now;
  final bool Function()? _isRateLimited;
  final void Function(int retryAfterSeconds)? _onRateLimited;
  final List<String> repos;
  final String cacheKey;

  @override
  Future<DataResult<MonitorDigest>> getDigest({bool force = false}) async {
    final now = _now().toUtc();
    final snapshot = await _readCached();
    final cached = snapshot.digest;
    final fresh = cached != null && await _isFresh(now);

    if (!force && fresh) {
      return DataResult(data: await _assembler.withStoredAlerts(cached, now), freshness: DataFreshness.freshCache, validatedAt: snapshot.validatedAt);
    }
    if (_isRateLimited?.call() ?? false) {
      return _fallbackResult(cached, now, snapshot.validatedAt, RepoCheckFailure.rateLimit);
    }
    try {
      final batch = await MonitorRefreshBatch.fetch(repos: repos, previous: cached?.checks ?? const {}, now: now, fetchRepo: (name) => _fetchRepo(name, now));
      final observed = {for (final item in batch.responses) item.repo.fullName.toLowerCase(): item.repo};
      final previous = {for (final repo in cached?.monitoredRepos ?? <RepoEntity>[]) repo.fullName.toLowerCase(): repo};
      final digest = _assembler.fromRepos([for (final name in repos) observed[name.toLowerCase()] ?? previous[name.toLowerCase()] ?? pendingMonitorRepo(name)], checks: batch.checks);
      // 失败仓库绝不被重新记成今天的观测，也不参与告警计算。
      await _assembler.recordObservationsAndAlerts(batch.responses, now);
      await _cache.upsert(key: cacheKey, payload: monitorDigestToJson(digest), now: now, validated: !batch.hasFailures);
      return DataResult(
        data: await _assembler.withStoredAlerts(digest, now),
        freshness: batch.hasFailures ? DataFreshness.staleCache : DataFreshness.live,
        validatedAt: batch.hasFailures ? snapshot.validatedAt : now,
        revalidated: !batch.hasFailures,
      );
    } catch (error) {
      _maybeReportRateLimit(error);
      AppLogger.warn('githubMonitorFallback', meta: {'error': error.runtimeType.toString()});
      return _fallbackResult(cached, now, snapshot.validatedAt, monitorCheckFailure(error));
    }
  }

  /* 限流或本地处理失败时，保留已观测值并持久化本次失败。 */
  Future<DataResult<MonitorDigest>> _fallbackResult(MonitorDigest? cached, DateTime now, DateTime? validatedAt, RepoCheckFailure failure) async {
    final previous = {for (final repo in cached?.monitoredRepos ?? <RepoEntity>[]) repo.fullName: repo};
    final digest = _assembler.fromRepos(
      [for (final name in repos) previous[name] ?? pendingMonitorRepo(name)],
      checks: {for (final name in repos) name: RepoCheckStatus(attemptedAt: now, validatedAt: cached?.checks[name]?.validatedAt, failure: failure)},
    );
    try {
      await _cache.upsert(key: cacheKey, payload: monitorDigestToJson(digest), now: now, validated: false);
    } catch (error) {
      AppLogger.warn('githubMonitorCacheStatus', meta: {'error': error.runtimeType.toString()});
    }
    return DataResult(data: await _assembler.withStoredAlerts(digest, now), freshness: DataFreshness.staleCache, validatedAt: validatedAt);
  }

  Future<bool> _isFresh(DateTime now) async {
    try {
      return await _cache.isFresh(key: cacheKey, ttl: monitorRemoteCacheTtl, now: now);
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

  /* 读取真实验证时间；旧缓存缺少逐仓库时间时保持未知。 */
  Future<({MonitorDigest? digest, DateTime? validatedAt})> _readCached() async {
    try {
      final entry = await _cache.readWithValidators(cacheKey);
      final json = entry.payload;
      if (json == null) {
        return (digest: null, validatedAt: null);
      }
      final validatedAt = entry.validatedAt;
      return (digest: monitorDigestFromJson(json), validatedAt: validatedAt?.millisecondsSinceEpoch == 0 ? null : validatedAt);
    } catch (error) {
      AppLogger.warn('githubMonitorCacheParse', meta: {'error': error.runtimeType.toString()});
      await _safeDeleteCache();
      return (digest: null, validatedAt: null);
    }
  }

  Future<GithubMonitorRemoteRepoItem> _fetchRepo(String fullName, DateTime now) async {
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
      // GitHub 仓库迁移可能重定向到新名称，订阅和检查状态仍按用户保存的标识关联。
      return _withSnapshotTrend(item.copyWith(repo: item.repo.copyWith(fullName: fullName)), now);
    } on DioException catch (error) {
      final exception = GitHubApiSupport.toAppException(error, now: _now);
      _maybeReportRateLimit(exception);
      throw exception;
    } on FormatException catch (error, stack) {
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    } on TypeError catch (error, stack) {
      throw AppException(kind: AppExceptionKind.parse, cause: error, stack: stack);
    }
  }

  Future<GithubMonitorRemoteRepoItem> _withSnapshotTrend(GithubMonitorRemoteRepoItem item, DateTime now) async {
    final history = _snapshotHistory;
    if (history == null) {
      return item;
    }
    await history.record(fullName: item.repo.fullName, stars: item.repo.starCount, forks: item.repo.forkCount, capturedAt: now);
    final starTrend = await history.starTrend(item.repo.fullName);
    if (starTrend == null) {
      return item;
    }
    return item.copyWith(
      repo: item.repo.copyWith(
        starDelta: _observedDelta(starTrend.values, fallback: item.repo.starDelta),
        trend: starTrend.values,
        trendDates: starTrend.dates,
        trendBasis: starTrend.basis,
      ),
    );
  }

  int _observedDelta(List<double> values, {required int fallback}) {
    if (values.length < 2) {
      return fallback;
    }
    return (values.last - values.first).round();
  }

  GithubMonitorRemoteRepoItem _parseRepo(Map<String, Object?> json, DateTime now) {
    final fullName = GitHubJson.string(json['full_name']);
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    final pushedAt = DateTime.tryParse(GitHubJson.string(json['pushed_at']))?.toUtc();
    final stars = GitHubJson.intValue(json['stargazers_count']);
    final forks = GitHubJson.intValue(json['forks_count']);
    final openIssues = GitHubJson.intValue(json['open_issues_count']);
    return GithubMonitorRemoteRepoItem(
      repo: RepoEntity(
        fullName: fullName,
        description: GitHubJson.nullableString(json['description']) ?? 'No description',
        language: language,
        starCount: stars,
        starDelta: 0,
        forkCount: forks,
        accentArgb: GitHubApiSupport.languageColor(language),
        valueBasis: MetricBasis.observed,
        trendBasis: MetricBasis.unavailable,
        trend: const [],
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }
}
