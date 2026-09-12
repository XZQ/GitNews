import '../../../core/domain/repo_check_status.dart';
import '../../../core/errors/app_exception.dart';
import 'github_monitor_remote_repo_item.dart';

/*
*逐仓库保留成功和失败结果，避免聚合时丢失用户监控项。
*/
class MonitorRefreshBatch {
  const MonitorRefreshBatch({required this.responses, required this.checks});

  // 仅本次远端成功的观测，可用于规则计算。
  final List<GithubMonitorRemoteRepoItem> responses;

  // 完整请求集合的检查状态。
  final Map<String, RepoCheckStatus> checks;

  // 任一失败都使整份摘要进入降级状态。
  bool get hasFailures => checks.values.any((check) => check.failure != null);

  /* 捕获单仓库失败，同时等待其他仓库完成。 */
  static Future<MonitorRefreshBatch> fetch({
    required List<String> repos,
    required Map<String, RepoCheckStatus> previous,
    required DateTime now,
    required Future<GithubMonitorRemoteRepoItem> Function(String fullName) fetchRepo,
  }) async {
    final checks = <String, RepoCheckStatus>{};
    final results = await Future.wait([
      for (final name in repos)
        () async {
          try {
            final response = await fetchRepo(name);
            checks[name] = RepoCheckStatus(attemptedAt: now, validatedAt: now);
            return response;
          } catch (error) {
            checks[name] = RepoCheckStatus(attemptedAt: now, validatedAt: previous[name]?.validatedAt, failure: monitorCheckFailure(error));
            return null;
          }
        }(),
    ]);
    return MonitorRefreshBatch(responses: results.whereType<GithubMonitorRemoteRepoItem>().toList(), checks: checks);
  }
}

/* 将网络与存储异常转换为可持久化的有限原因。 */
RepoCheckFailure monitorCheckFailure(Object error) => switch (error) {
  AppException(:final kind) => switch (kind) {
    AppExceptionKind.network => RepoCheckFailure.network,
    AppExceptionKind.rateLimit => RepoCheckFailure.rateLimit,
    AppExceptionKind.unauthorized => RepoCheckFailure.unauthorized,
    AppExceptionKind.notFound => RepoCheckFailure.notFound,
    AppExceptionKind.parse => RepoCheckFailure.parse,
    AppExceptionKind.server => RepoCheckFailure.server,
    AppExceptionKind.cache => RepoCheckFailure.cache,
    AppExceptionKind.unknown => RepoCheckFailure.unknown,
  },
  _ => RepoCheckFailure.unknown,
};
