import 'dart:math' as math;

import 'entities.dart';
import 'monitor_observation.dart';
import 'monitor_rule.dart';

class MonitorRuleEvaluator {
  const MonitorRuleEvaluator();

  List<MonitorAlertEvent> evaluate({
    required MonitorObservation? previous,
    required MonitorObservation current,
    required Set<String> enabledRuleIds,
  }) {
    if (previous == null || previous.repoFullName != current.repoFullName || previous.localDayKey == current.localDayKey) {
      return const [];
    }

    final starDelta = math.max(0, current.stars - previous.stars).toDouble();
    final forkDelta = math.max(0, current.forks - previous.forks).toDouble();
    final starRate = previous.stars <= 0 ? 0.0 : starDelta / previous.stars * 100;
    final issueRatio = (current.openIssues + 1) / (previous.openIssues + 1);
    final events = <MonitorAlertEvent>[];

    void addIfTriggered({
      required String ruleId,
      required String metric,
      required double value,
      required double threshold,
      required AlertSeverity severity,
    }) {
      if (!enabledRuleIds.contains(ruleId) || value < threshold) {
        return;
      }
      events.add(
        MonitorAlertEvent(
          id: '${current.repoFullName}|$ruleId|${current.localDayKey}',
          repoFullName: current.repoFullName,
          ruleId: ruleId,
          metric: metric,
          value: value,
          threshold: threshold,
          severity: severity,
          observedAt: current.observedAt.toUtc(),
        ),
      );
    }

    addIfTriggered(
      ruleId: MonitorRuleIds.starDailyDelta,
      metric: 'stars',
      value: starDelta,
      threshold: MonitorRuleThresholds.starDailyDelta,
      severity: AlertSeverity.success,
    );
    addIfTriggered(
      ruleId: MonitorRuleIds.starDailyRate,
      metric: 'starRate',
      value: starRate,
      threshold: MonitorRuleThresholds.starDailyRate,
      severity: AlertSeverity.warning,
    );
    addIfTriggered(
      ruleId: MonitorRuleIds.forkDailyDelta,
      metric: 'forks',
      value: forkDelta,
      threshold: MonitorRuleThresholds.forkDailyDelta,
      severity: AlertSeverity.info,
    );
    addIfTriggered(
      ruleId: MonitorRuleIds.issueHeatRatio,
      metric: 'openIssuesRatio',
      value: issueRatio,
      threshold: MonitorRuleThresholds.issueHeatRatio,
      severity: AlertSeverity.danger,
    );

    return events;
  }
}
