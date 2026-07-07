import '../../../core/domain/repo_entity.dart';
import 'entities.dart';

/* 
*监控模块需要的本地情报数据。
*/
class MonitorDigest {
  const MonitorDigest({
    required this.monitoredRepos,
    required this.alerts,
    required this.stats,
  });

  final List<RepoEntity> monitoredRepos;
  final List<AlertEntity> alerts;
  final MonitorStats stats;

  bool get isEmpty => monitoredRepos.isEmpty && alerts.isEmpty;

  RepoEntity? repoByFullName(String repoFullName) {
    final decoded = Uri.decodeComponent(repoFullName);
    for (final repo in monitoredRepos) {
      if (repo.fullName == decoded) return repo;
    }
    return null;
  }
}

/* 
*监控数据仓库。
*当前实现默认读取 GitHub Repository API 并使用本地快照缓存;远端失败时可
*回退过期缓存或本地监控种子数据。
*/
abstract interface class MonitorRepository {
  Future<MonitorDigest> getDigest();
}
