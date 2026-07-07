/*
*远端 API 端点配置。
*集中管理各数据源的 baseUrl 与请求路径,避免散落字符串与重复字面量。
*路径分两类:
*- 静态路径(如 `/rate_limit`):直接 `static const String`。
*- 模板路径(如 `/repos/$fullName`):提供静态方法,注入参数后返回完整路径。
*/
class ApiEndpointsConfig {
  const ApiEndpointsConfig._();

  // AI 动态 baseUrl(aihot.virxact.com 公开精选流)。
  static const String aiNewsBaseUrl = 'https://aihot.virxact.com';

  // AI 动态列表接口:`GET /api/public/items`。
  static const String aiNewsItemsPath = '/api/public/items';

  // GitHub REST API 默认 baseUrl。
  static const String githubBaseUrl = 'https://api.github.com';

  // GitHub Search 仓库搜索接口:`GET /search/repositories`。
  static const String githubSearchRepositoriesPath = '/search/repositories';

  // GitHub rate_limit 接口:`GET /rate_limit`。
  static const String githubRateLimitPath = '/rate_limit';

  // GitHub 仓库详情接口:`GET /repos/{fullName}`。
  static String githubRepoPath(String fullName) => '/repos/$fullName';

  // GitHub 仓库贡献者接口:`GET /repos/{fullName}/contributors`。
  static String githubRepoContributorsPath(String fullName) =>
      '/repos/$fullName/contributors';
}
