import '../../../core/demo_data.dart';

/// 监控页的统计摘要。
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

/// 监控模块需要的本地情报数据。
class MonitorDigest {
  const MonitorDigest({
    required this.monitoredRepos,
    required this.alerts,
    required this.stats,
  });

  final List<DemoRepo> monitoredRepos;
  final List<DemoAlert> alerts;
  final MonitorStats stats;

  bool get isEmpty => monitoredRepos.isEmpty && alerts.isEmpty;

  DemoRepo repoByFullName(String repoFullName) {
    final decoded = Uri.decodeComponent(repoFullName);
    return monitoredRepos.firstWhere(
      (repo) => repo.fullName == decoded,
      orElse: () => monitoredRepos.first,
    );
  }
}

/// 监控数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为 GitHub API + 本地规则缓存。
abstract interface class MonitorRepository {
  Future<MonitorDigest> getDigest();
}
