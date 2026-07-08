import '../../../core/github/github_api_support.dart';
import '../../../core/github/github_repo_entity_codec.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';

Map<String, Object?> monitorDigestToJson(MonitorDigest digest) {
  return {
    'repos': digest.monitoredRepos.map(githubRepoEntityToJson).toList(),
    'alerts': digest.alerts.map(_alertToJson).toList(),
    'stats': _statsToJson(digest.stats),
  };
}

MonitorDigest monitorDigestFromJson(Map<String, Object?> json) {
  return MonitorDigest(
    monitoredRepos: GitHubJson.list(
      json['repos'],
    ).map(githubRepoEntityFromJson).toList(),
    alerts: GitHubJson.list(json['alerts']).map(_alertFromJson).toList(),
    stats: _statsFromJson(GitHubJson.map(json['stats'])),
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
