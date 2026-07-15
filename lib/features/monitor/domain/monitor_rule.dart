import 'entities.dart';

class MonitorRuleIds {
  const MonitorRuleIds._();

  static const String starDailyDelta = 'star_daily_delta';
  static const String starDailyRate = 'star_daily_rate';
  static const String forkDailyDelta = 'fork_daily_delta';
  static const String issueHeatRatio = 'issue_heat_ratio';

  static const Set<String> all = {starDailyDelta, starDailyRate, forkDailyDelta, issueHeatRatio};
}

class MonitorRuleThresholds {
  const MonitorRuleThresholds._();

  static const double starDailyDelta = 200;
  static const double starDailyRate = 10;
  static const double forkDailyDelta = 50;
  static const double issueHeatRatio = 5;
}

class MonitorAlertEvent {
  const MonitorAlertEvent(
      {required this.id,
      required this.repoFullName,
      required this.ruleId,
      required this.metric,
      required this.value,
      required this.threshold,
      required this.severity,
      required this.observedAt,
      this.readAt,
      this.archivedAt});

  final String id;
  final String repoFullName;
  final String ruleId;
  final String metric;
  final double value;
  final double threshold;
  final AlertSeverity severity;
  final DateTime observedAt;
  final DateTime? readAt;
  final DateTime? archivedAt;

  bool get isRead => readAt != null;
  bool get isArchived => archivedAt != null;

  MonitorAlertEvent copyWith({
    DateTime? readAt,
    DateTime? archivedAt,
    bool clearReadAt = false,
    bool clearArchivedAt = false,
  }) {
    return MonitorAlertEvent(
      id: id,
      repoFullName: repoFullName,
      ruleId: ruleId,
      metric: metric,
      value: value,
      threshold: threshold,
      severity: severity,
      observedAt: observedAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}
