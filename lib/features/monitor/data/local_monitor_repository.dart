import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../../../core/domain/data_freshness.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';

/* 
*基于本地模拟数据的监控仓库。
*/
class LocalMonitorRepository implements MonitorRepository {
  const LocalMonitorRepository();

  @override
  Future<DataResult<MonitorDigest>> getDigest({bool force = false}) async {
    return DataResult(
      freshness: DataFreshness.seed,
      data: MonitorDigest(
        monitoredRepos: [...DemoData.trending, ...DemoData.recent].map((e) => e.toEntity()).toList(),
        alerts: const [],
        stats: const MonitorStats(
          monitoredCount: 28,
          monitoredDelta: 4,
          unreadAlertCount: 0,
          unreadAlertDelta: 0,
          triggeredTodayCount: 0,
          triggeredTodayDelta: 0,
          totalAlertCount: 0,
          totalAlertDelta: 0,
        ),
      ),
    );
  }
}
