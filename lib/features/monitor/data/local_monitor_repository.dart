import '../../../core/demo_data.dart';
import '../domain/monitor_repository.dart';

/// 基于本地模拟数据的监控仓库。
class LocalMonitorRepository implements MonitorRepository {
  const LocalMonitorRepository();

  @override
  Future<MonitorDigest> getDigest() async {
    return const MonitorDigest(
      monitoredRepos: [...DemoData.trending, ...DemoData.recent],
      alerts: DemoData.alerts,
      stats: MonitorStats(
        monitoredCount: 28,
        monitoredDelta: 4,
        unreadAlertCount: 4,
        unreadAlertDelta: -2,
        triggeredTodayCount: 3,
        triggeredTodayDelta: 1,
        totalAlertCount: 12,
        totalAlertDelta: -5,
      ),
    );
  }
}
