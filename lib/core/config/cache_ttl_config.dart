/* 
*远端缓存 TTL 配置。
*集中管理各模块的缓存时长,避免散落的 `Duration(minutes: 5)`。
*分级原则:
*- 列表/榜单(trending / ai_news / tech_hotspot):用户感知最强,5 分钟
*- 监控仓库(monitor):后台监控可略长,10 分钟
*- 仓库详情(repo_detail):相对稳定,30 分钟
*- 项目报告(project):聚合产物,30 分钟
*/
class CacheTtlConfig {
  const CacheTtlConfig._();

  // 热榜(GitHub Search 聚合)。
  static const Duration trending = Duration(minutes: 5);

  // AI 资讯(分类列表)。
  static const Duration aiNews = Duration(minutes: 5);

  // 技术热点(AI 雷达多 topic 聚合)。
  static const Duration techHotspot = Duration(minutes: 5);

  // 监控仓库(后台聚合)。
  static const Duration monitor = Duration(minutes: 10);

  // 仓库详情(基本字段 + contributors + 相关仓库)。
  static const Duration repoDetail = Duration(minutes: 30);

  // 深度报告(基于 trending + contributors 的二次聚合)。
  static const Duration project = Duration(minutes: 30);
}
