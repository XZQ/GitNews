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

  // GitHub 仓库搜索(发现页:按 stars 排序的流行仓库 / AI Agent Skills 仓库)。
  // 返回完整 query path,与 [githubBaseUrl] 拼接后直接 GET。
  static String githubSearchRepositoriesUrl({
    String q = 'stars:>1000',
    String sort = 'stars',
    String order = 'desc',
    int perPage = 20,
    int page = 1,
  }) =>
      '/search/repositories?q=${Uri.encodeQueryComponent(q)}'
      '&sort=$sort&order=$order&per_page=$perPage&page=$page';

  // GitHub 用户/组织公开资料:`GET /users/{login}`。
  static String githubPublicUserPath(String login) => '/users/$login';

  // GitHub 用户详情(Device Flow 登录后回填真实用户名/头像):`GET /user`。
  static String githubUserPath = '/user';

  // GitHub OAuth Device Flow:获取 device_code / user_code。
  static String githubDeviceCodePath = '/login/device/code';

  // GitHub OAuth Device Flow:轮询换取 access_token。
  static String githubDeviceTokenPath = '/login/oauth/access_token';

  // GitHub OAuth Device Flow 的 client_id。
  // 注意:需替换为在 GitHub 注册的 OAuth App 的 client_id(桌面应用启用 Device Flow)。
  static const String githubOAuthClientId = 'YOUR_OAUTH_APP_CLIENT_ID';

  // 第三方 Agent Skills 排行榜数据源 baseUrl(raw.githubusercontent.com)。
  // 注意:该端点未验证可用(jaychempan/Agent-Skills-Leaderboard 路径 2026-07 核查 404),
  // 当前 discover 模块以 GitHub Search API(topic:agent-skills 等)为主数据源,
  // 此处仅保留占位,待确认可靠数据源后再启用,避免误用死链。
  static const String agentSkillsLeaderboardBaseUrl =
      'https://raw.githubusercontent.com';

  static String agentSkillsLeaderboardPath(String kind) =>
      '/jaychempan/Agent-Skills-Leaderboard/main/data/$kind.json';
}
