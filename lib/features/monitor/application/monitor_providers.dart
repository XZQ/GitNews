import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/repo_entity.dart';
import '../data/local_monitor_repository.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return const LocalMonitorRepository();
});

final monitorDigestProvider = FutureProvider<MonitorDigest>((ref) {
  return ref.watch(monitorRepositoryProvider).getDigest();
});

/// 仓库监控顶部搜索关键词。空字符串表示不过滤当前监控数据。
final monitorSearchQueryProvider = StateProvider<String>((ref) => '');

/// 应用本地搜索后的监控摘要。
final filteredMonitorDigestProvider =
    FutureProvider<MonitorDigest>((ref) async {
  final query = ref.watch(monitorSearchQueryProvider);
  final digest = await ref.watch(monitorDigestProvider.future);
  return filterMonitorDigest(digest, query);
});

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
