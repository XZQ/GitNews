import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_monitor_config.dart';
import '../data/github_monitor_repository.dart';
import '../data/local_monitor_repository.dart';
import '../data/monitor_observation_dao.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import '../domain/monitor_rule.dart';
import 'monitor_alert_state_controller.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  final monitored = ref.watch(localContentControllerProvider).monitoredRepos;
  final ruleToggles = ref.watch(localContentControllerProvider).monitorRules;
  final repos = monitorReposFor(monitored);
  return GithubMonitorRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    observationDao: MonitorObservationDao(ref.watch(jsonSnapshotCacheDaoProvider)),
    alertDao: ref.watch(monitorAlertEventDaoProvider),
    enabledRuleIds: _enabledRuleIds(ruleToggles),
    snapshotHistory: ref.watch(repoSnapshotHistoryDaoProvider),
    token: token,
    repos: repos,
    cacheKey: _monitorCacheKey(repos),
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

List<String> monitorReposFor(Set<String> monitored) {
  return monitored.toList()..sort();
}

// 监控缓存 key:默认仓库集合沿用历史 key,用户自定义集合按内容哈希隔离,
// 避免不同监控列表互相覆盖缓存。
String _monitorCacheKey(List<String> repos) {
  if (repos.length == githubMonitorDefaultRepos.length) {
    final set = repos.toSet();
    if (set.containsAll(githubMonitorDefaultRepos)) {
      return githubMonitorCacheKey;
    }
  }
  final buffer = repos.join(',');
  var hash = 0;
  for (final unit in buffer.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return 'monitor:github:user_$hash';
}

// 兼容测试 override 与本地兜底。
final localMonitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return const LocalMonitorRepository();
});

final monitorDigestResultProvider = AsyncNotifierProvider<MonitorDigestNotifier, DataResult<MonitorDigest>>(MonitorDigestNotifier.new);

final monitorRefreshInProgressProvider = Provider<bool>((ref) => ref.watch(monitorDigestResultProvider).isLoading);

/*
*刷新直接发布本次结果，避免刷新后失效 provider 再请求一次。
*/
class MonitorDigestNotifier extends AsyncNotifier<DataResult<MonitorDigest>> {
  // 下一次构建是否绕过 TTL。
  bool _forceNextBuild = false;

  // 多个入口共享同一次刷新。
  Future<void>? _refreshTask;

  @override
  /* Riverpod 在仓库集合变更时隔离旧请求的结果。 */
  Future<DataResult<MonitorDigest>> build() {
    final force = _forceNextBuild;
    _forceNextBuild = false;
    return ref.watch(monitorRepositoryProvider).getDigest(force: force);
  }

  /* 合并重复点击并等待实际检查结果。 */
  Future<void> refresh() => _refreshTask ??= _refresh().whenComplete(() => _refreshTask = null);

  /* 由 provider 自身重建，保留已显示的数据直到新结果到达。 */
  Future<void> _refresh() async {
    _forceNextBuild = true;
    ref.invalidateSelf();
    await future;
    if (ref.mounted) {
      ref.invalidate(monitorAlertEventsProvider);
    }
  }
}

final monitorDigestProvider = FutureProvider<MonitorDigest>((ref) async {
  return (await ref.watch(monitorDigestResultProvider.future)).data;
});

// 将仓库数据与独立持久化的告警状态合并为界面唯一读取的监控摘要。
final visibleMonitorDigestProvider = FutureProvider<MonitorDigest>((ref) async {
  final digest = await ref.watch(monitorDigestProvider.future);
  final events = await ref.watch(monitorAlertEventsProvider.future);
  return applyMonitorAlertEvents(digest, events, ref.watch(monitorAlertClockProvider)());
});

final monitorFreshnessProvider = Provider<AsyncValue<DataFreshness>>((ref) {
  return ref.watch(monitorDigestResultProvider).whenData((result) => result.freshness);
});

// 仓库监控顶部搜索关键词。空字符串表示不过滤当前监控数据。
final monitorSearchQueryProvider = StateProvider<String>((ref) => '');

// 应用本地搜索后的监控摘要。
final filteredMonitorDigestProvider = FutureProvider<MonitorDigest>((ref) async {
  final query = ref.watch(monitorSearchQueryProvider);
  final digest = await ref.watch(visibleMonitorDigestProvider.future);
  return filterMonitorDigest(digest, query);
});

Set<String> _enabledRuleIds(List<bool> toggles) {
  const ids = [MonitorRuleIds.starDailyDelta, MonitorRuleIds.starDailyRate, MonitorRuleIds.forkDailyDelta, MonitorRuleIds.issueHeatRatio];
  return {
    for (var index = 0; index < ids.length; index++)
      if (index < toggles.length && toggles[index]) ids[index],
  };
}

/* 页面点击等待检查；异常由 provider 的错误状态展示，避免异步回调再次抛出。 */
Future<void> forceRefreshMonitor(WidgetRef ref) async {
  try {
    await ref.read(monitorDigestResultProvider.notifier).refresh();
  } catch (_) {
    // monitorDigestResultProvider 已保留失败，页面显示错误与重试入口。
  }
}

MonitorDigest applyMonitorAlertEvents(MonitorDigest digest, Iterable<MonitorAlertEvent> events, DateTime now) {
  final visibleEvents = events.where((event) => !event.isArchived).toList()..sort((left, right) => right.observedAt.compareTo(left.observedAt));
  final alerts = [
    for (final event in visibleEvents)
      AlertEntity(
        id: event.id,
        repoFullName: event.repoFullName,
        ruleId: event.ruleId,
        metric: event.ruleId,
        value: _formatMonitorAlertValue(event),
        time: githubMonitorRelativeTime(event.observedAt, now),
        severity: event.severity,
        observedAt: event.observedAt,
        readAt: event.readAt,
        archivedAt: event.archivedAt,
      ),
  ];
  final todayCount = visibleEvents.where((event) => _isSameLocalDay(event.observedAt, now)).length;

  return MonitorDigest(
    monitoredRepos: digest.monitoredRepos,
    checks: digest.checks,
    alerts: alerts,
    stats: MonitorStats(
      monitoredCount: digest.monitoredRepos.length,
      monitoredDelta: digest.stats.monitoredDelta,
      unreadAlertCount: visibleEvents.where((event) => !event.isRead).length,
      unreadAlertDelta: 0,
      triggeredTodayCount: todayCount,
      triggeredTodayDelta: 0,
      totalAlertCount: visibleEvents.length,
      totalAlertDelta: 0,
    ),
  );
}

String _formatMonitorAlertValue(MonitorAlertEvent event) {
  final value = event.value;
  switch (event.ruleId) {
    case MonitorRuleIds.starDailyRate:
      return '${value.toStringAsFixed(1)}%';
    case MonitorRuleIds.issueHeatRatio:
      return '${value.toStringAsFixed(1)}x';
    default:
      final formatted = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
      return '+$formatted';
  }
}

bool _isSameLocalDay(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year && localLeft.month == localRight.month && localLeft.day == localRight.day;
}

MonitorDigest filterMonitorDigest(MonitorDigest digest, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return digest;
  }

  return MonitorDigest(monitoredRepos: filterMonitorRepos(digest.monitoredRepos, keyword), alerts: filterMonitorAlerts(digest.alerts, keyword), stats: digest.stats, checks: digest.checks);
}

List<RepoEntity> filterMonitorRepos(List<RepoEntity> repos, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return repos;
  }

  return [
    for (final repo in repos)
      if (_repoSearchText(repo).contains(keyword)) repo,
  ];
}

List<AlertEntity> filterMonitorAlerts(List<AlertEntity> alerts, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return alerts;
  }

  return [
    for (final alert in alerts)
      if (_alertSearchText(alert).contains(keyword)) alert,
  ];
}

String _repoSearchText(RepoEntity repo) {
  return [repo.fullName, repo.description, repo.language].join(' ').toLowerCase();
}

String _alertSearchText(AlertEntity alert) {
  return [alert.repoFullName, alert.metric, alert.value, alert.time, alert.severity.name].join(' ').toLowerCase();
}
