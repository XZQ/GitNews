/* 
*监控告警严重级别。
*/
enum AlertSeverity { info, success, warning, danger }

/* 
*监控告警实体。
*/
class AlertEntity {
  const AlertEntity({
    required this.repoFullName,
    required this.metric,
    required this.value,
    required this.time,
    required this.severity,
  });

  final String repoFullName;
  final String metric;
  final String value;

  // 友好相对时间(展示层按需二次格式化)。
  final String time;
  final AlertSeverity severity;
}

/* 
*监控统计摘要。
*/
class MonitorStats {
  const MonitorStats({
    required this.monitoredCount,
    required this.monitoredDelta,
    required this.unreadAlertCount,
    required this.unreadAlertDelta,
    required this.triggeredTodayCount,
    required this.triggeredTodayDelta,
    required this.totalAlertCount,
    required this.totalAlertDelta,
  });

  final int monitoredCount;
  final int monitoredDelta;
  final int unreadAlertCount;
  final int unreadAlertDelta;
  final int triggeredTodayCount;
  final int triggeredTodayDelta;
  final int totalAlertCount;
  final int totalAlertDelta;
}
