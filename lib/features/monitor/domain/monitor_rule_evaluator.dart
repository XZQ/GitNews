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
    if (previous == null || previous.repoFullName != current.repoFullName) {
      return const [];
    }

    final elapsedDays = _elapsedLocalDays(
      previous.observedAt,
      current.observedAt,
    );
    if (elapsedDays <= 0) {
      return const [];
    }
    final starDelta = math.max(0, current.stars - previous.stars) / elapsedDays;
    final forkDelta = math.max(0, current.forks - previous.forks) / elapsedDays;
    final starRate = previous.stars <= 0 || current.stars <= previous.stars
        ? 0.0
        : (math
                    .pow(
                      current.stars / previous.stars,
                      1 / elapsedDays,
                    )
                    .toDouble() -
                1) *
            100;
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

  int _elapsedLocalDays(DateTime previous, DateTime current) {
    final previousLocal = previous.toLocal();
    final currentLocal = current.toLocal();
    final previousDay = DateTime(
      previousLocal.year,
      previousLocal.month,
      previousLocal.day,
    );
    final currentDay = DateTime(
      currentLocal.year,
      currentLocal.month,
      currentLocal.day,
    );
    return currentDay.difference(previousDay).inDays;
  }
}
