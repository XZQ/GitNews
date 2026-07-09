/* 
*全局搜索关键词路由配置。
*首页搜索框根据用户输入的关键词智能路由到对应功能模块。
*关键词匹配规则：小写化后检查是否包含任一关键词。
*/
class SearchRouteEntry {
  const SearchRouteEntry({
    required this.route,
    required this.keywords,
    required this.searchQueryProviderSetter,
  });

  // 目标路由路径。
  final String route;

  // 触发关键词列表（小写）。
  final List<String> keywords;

  /* 
  *匹配后执行的 searchQueryProvider setter（由调用方注入）。
  */
  final void Function(String query) searchQueryProviderSetter;
}

/* 
*全局搜索关键词路由表。
*匹配顺序：从上到下，首个命中即返回。
*默认 fallback：`/trending`。
*/
class GlobalSearchRouter {
  const GlobalSearchRouter._();

  /* 
  *构建路由表。setter 回调由调用方注入（避免 config 层依赖 feature providers）。
  */
  static List<SearchRouteEntry> build({
    required void Function(String) aiNewsSetter,
    required void Function(String) techHotspotSetter,
    required void Function(String) monitorSetter,
    required void Function(String) projectSetter,
    required void Function(String) trendingSetter,
  }) {
    return [
      SearchRouteEntry(
        route: '/ai_news',
        keywords: const [
          'ai',
          'openai',
          'anthropic',
          'gemini',
          '模型',
          '资讯',
          '新闻',
          '论文',
        ],
        searchQueryProviderSetter: aiNewsSetter,
      ),
      SearchRouteEntry(
        route: '/tech_hotspot',
        keywords: const ['agent', 'mcp', 'coding', 'rag', '智能体', '雷达', '本地推理'],
        searchQueryProviderSetter: techHotspotSetter,
      ),
      SearchRouteEntry(
        route: '/monitor',
        keywords: const ['monitor', 'alert', '告警', '监控', '规则'],
        searchQueryProviderSetter: monitorSetter,
      ),
      SearchRouteEntry(
        route: '/project',
        keywords: const [
          'report',
          '报告',
          '周报',
          '贡献者',
          'developer',
          'contributor',
        ],
        searchQueryProviderSetter: projectSetter,
      ),
    ];
  }

  // 默认 fallback 路由。
  static const String fallbackRoute = '/trending';

  /* 
  *执行搜索路由。
  */
  static void route({
    required String rawQuery,
    required List<SearchRouteEntry> entries,
    required void Function(String) fallbackSetter,
    required void Function(String route) onRoute,
  }) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    final normalized = query.toLowerCase();
    for (final entry in entries) {
      if (entry.keywords.any(normalized.contains)) {
        entry.searchQueryProviderSetter(query);
        onRoute(entry.route);
        return;
      }
    }

    fallbackSetter(query);
    onRoute(fallbackRoute);
  }
}
