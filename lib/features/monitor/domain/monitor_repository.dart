import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_check_status.dart';
import '../../../core/domain/repo_entity.dart';
import 'entities.dart';

/* 
*监控模块需要的本地情报数据。
*/
class MonitorDigest {
  const MonitorDigest({required this.monitoredRepos, required this.alerts, required this.stats, this.checks = const {}});

  final List<RepoEntity> monitoredRepos;
  final List<AlertEntity> alerts;
  final MonitorStats stats;

  // 按仓库全名保存的检查状态；旧版缓存可为空。
  final Map<String, RepoCheckStatus> checks;

  bool get isEmpty => monitoredRepos.isEmpty && alerts.isEmpty;

  RepoEntity? repoByFullName(String repoFullName) {
    final decoded = Uri.decodeComponent(repoFullName);
    for (final repo in monitoredRepos) {
      if (repo.fullName == decoded) {
        return repo;
      }
    }
    return null;
  }
}

/* 
*监控数据仓库。
*当前实现默认读取 GitHub Repository API 并使用本地快照缓存;远端失败时可
*回退过期快照；无快照时保留用户选择的仓库并标记数值未观测。
*/
abstract interface class MonitorRepository {
  Future<DataResult<MonitorDigest>> getDigest({bool force = false});
}
