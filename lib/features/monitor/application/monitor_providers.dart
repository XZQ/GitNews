import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_monitor_config.dart';
import '../data/github_monitor_repository.dart';
import '../data/local_monitor_repository.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'monitor_alert_state_controller.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  final monitored = ref.watch(localContentControllerProvider).monitoredRepos;
  final repos =
      monitored.isEmpty ? githubMonitorDefaultRepos : monitored.toList();
  return GithubMonitorRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    snapshotHistory: ref.watch(repoSnapshotHistoryDaoProvider),
    token: token,
    repos: repos,
    cacheKey: _monitorCacheKey(repos),
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

/// 监控缓存 key:默认仓库集合沿用历史 key,用户自定义集合按内容哈希隔离,
/// 避免不同监控列表互相覆盖缓存。
String _monitorCacheKey(List<String> repos) {
  if (repos.length == githubMonitorDefaultRepos.length) {
    final set = repos.toSet();
    if (set.containsAll(githubMonitorDefaultRepos)) return githubMonitorCacheKey;
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

final monitorDigestProvider = FutureProvider<MonitorDigest>((ref) {
  return ref.watch(monitorRepositoryProvider).getDigest();
});

// 仓库监控顶部搜索关键词。空字符串表示不过滤当前监控数据。
final monitorSearchQueryProvider = StateProvider<String>((ref) => '');

// 应用本地搜索后的监控摘要。
final filteredMonitorDigestProvider =
    FutureProvider<MonitorDigest>((ref) async {
  final query = ref.watch(monitorSearchQueryProvider);
  final digest = await ref.watch(monitorDigestProvider.future);
  final alertState = ref.watch(monitorAlertStateControllerProvider);
  return filterMonitorDigest(applyMonitorAlertState(digest, alertState), query);
});

MonitorDigest applyMonitorAlertState(
  MonitorDigest digest,
  MonitorAlertState alertState,
) {
  final visibleAlerts = alertState.visibleAlerts(digest.alerts);
  return MonitorDigest(
    monitoredRepos: digest.monitoredRepos,
    alerts: visibleAlerts,
    stats: MonitorStats(
      monitoredCount: digest.stats.monitoredCount,
      monitoredDelta: digest.stats.monitoredDelta,
      unreadAlertCount: alertState.unreadCount(digest.alerts),
      unreadAlertDelta: digest.stats.unreadAlertDelta,
      triggeredTodayCount: visibleAlerts.length,
      triggeredTodayDelta: digest.stats.triggeredTodayDelta,
      totalAlertCount: visibleAlerts.length,
      totalAlertDelta: digest.stats.totalAlertDelta,
    ),
  );
}

MonitorDigest filterMonitorDigest(MonitorDigest digest, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return digest;

  return MonitorDigest(
    monitoredRepos: filterMonitorRepos(digest.monitoredRepos, keyword),
    alerts: filterMonitorAlerts(digest.alerts, keyword),
    stats: digest.stats,
  );
}

List<RepoEntity> filterMonitorRepos(List<RepoEntity> repos, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return repos;

  return [
    for (final repo in repos)
      if (_repoSearchText(repo).contains(keyword)) repo,
  ];
}

List<AlertEntity> filterMonitorAlerts(List<AlertEntity> alerts, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return alerts;

  return [
    for (final alert in alerts)
      if (_alertSearchText(alert).contains(keyword)) alert,
  ];
}

String _repoSearchText(RepoEntity repo) {
  return [
    repo.fullName,
    repo.description,
    repo.language,
  ].join(' ').toLowerCase();
}

String _alertSearchText(AlertEntity alert) {
  return [
    alert.repoFullName,
    alert.metric,
    alert.value,
    alert.time,
    alert.severity.name,
  ].join(' ').toLowerCase();
}
