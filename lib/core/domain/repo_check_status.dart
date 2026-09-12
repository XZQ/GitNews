/*
*一次仓库检查的受控失败原因，不保存网络响应或凭据。
*/
enum RepoCheckFailure {
  // 网络连接或超时失败。
  network,
  // GitHub 请求额度耗尽。
  rateLimit,
  // 凭据无效或仓库不可访问。
  unauthorized,
  // 仓库不存在。
  notFound,
  // 返回数据无法解析。
  parse,
  // 上游服务异常。
  server,
  // 本地保存失败。
  cache,
  // 其他未分类失败。
  unknown,
}

/*
*仓库检查元数据：尝试时间与成功观测时间分开保存。
*/
class RepoCheckStatus {
  const RepoCheckStatus({this.attemptedAt, this.validatedAt, this.failure});

  // 最近一次请求或受限重试的时间。
  final DateTime? attemptedAt;

  // 最近一次成功观测时间，失败不推进。
  final DateTime? validatedAt;

  // 最近检查的失败原因；null 不代表一定存在成功观测。
  final RepoCheckFailure? failure;
}
