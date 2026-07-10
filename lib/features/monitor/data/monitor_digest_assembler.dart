import '../domain/entities.dart';
import '../domain/monitor_observation.dart';
import '../domain/monitor_repository.dart';
import '../domain/monitor_rule.dart';
import '../domain/monitor_rule_evaluator.dart';
import 'github_monitor_config.dart';
import 'github_monitor_remote_repo_item.dart';
import 'monitor_alert_event_dao.dart';
import 'monitor_observation_dao.dart';

class MonitorDigestAssembler {
  const MonitorDigestAssembler({
    required MonitorObservationDao observationDao,
    required MonitorAlertEventDao alertDao,
    required MonitorRuleEvaluator evaluator,
    required Set<String> enabledRuleIds,
  })  : _observationDao = observationDao,
        _alertDao = alertDao,
        _evaluator = evaluator,
        _enabledRuleIds = enabledRuleIds;

  final MonitorObservationDao _observationDao;
  final MonitorAlertEventDao _alertDao;
  final MonitorRuleEvaluator _evaluator;
  final Set<String> _enabledRuleIds;

  MonitorDigest fromResponses(List<GithubMonitorRemoteRepoItem> responses) {
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

  Future<void> recordObservationsAndAlerts(
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

  Future<MonitorDigest> withStoredAlerts(
    MonitorDigest digest,
    DateTime now,
  ) async {
    final stored = await _alertDao.list(includeArchived: true);
    final visible = stored.where((event) => !event.isArchived).toList();
    return MonitorDigest(
      monitoredRepos: digest.monitoredRepos,
      alerts: [for (final event in visible) _toAlertEntity(event, now)],
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

  bool _isToday(DateTime value, DateTime now) {
    final local = value.toLocal();
    final today = now.toLocal();
    return local.year == today.year && local.month == today.month && local.day == today.day;
  }
}
