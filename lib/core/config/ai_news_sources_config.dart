/*
*AI 动态补充 RSS/Atom 源配置。
*背景:主源 aihot.virxact.com 是单点,任一时刻失效整个模块只剩缓存;
*这里声明式维护一组官方/权威补充源,由 ai_news 的聚合仓库并行拉取合并。
*约束:core 不依赖 feature,因此分类用字符串 code(与
*`AiNewsCategory.code` 对齐),由 feature 侧反查枚举。
*全部 feedUrl 于 2026-07-14 核验可用;新增源只需追加一条配置。
*/
class AiNewsSourceConfig {
  const AiNewsSourceConfig({
    required this.id,
    required this.name,
    required this.feedUrl,
    required this.categoryCode,
  });

  // 稳定源标识,参与条目 id 生成,改名不要改 id。
  final String id;

  // 展示用来源名。
  final String name;

  // RSS 2.0 或 Atom feed 完整 URL。
  final String feedUrl;

  // 该源条目的默认分类(`AiNewsCategory.code`)。
  final String categoryCode;
}

class AiNewsSourcesConfig {
  const AiNewsSourcesConfig._();

  // 自定义源可选择的分类编码,与 AI 资讯领域枚举保持稳定协议。
  static const List<String> supportedCategoryCodes = ['ai-models', 'ai-products', 'paper', 'tip', 'industry'];

  // 每个源单次聚合最多贡献的条目数,防止高频源淹没时间线。
  static const int maxItemsPerSource = 20;

  // 聚合时丢弃早于该窗口的条目,避免首次接入时灌入陈年存档。
  static const Duration recencyWindow = Duration(days: 30);

  static const List<AiNewsSourceConfig> sources = [
    AiNewsSourceConfig(
      id: 'openai_news',
      name: 'OpenAI News',
      feedUrl: 'https://openai.com/news/rss.xml',
      categoryCode: 'ai-products',
    ),
    AiNewsSourceConfig(
      id: 'huggingface_blog',
      name: 'Hugging Face Blog',
      feedUrl: 'https://huggingface.co/blog/feed.xml',
      categoryCode: 'tip',
    ),
    AiNewsSourceConfig(
      id: 'google_ai_blog',
      name: 'Google AI Blog',
      feedUrl: 'https://blog.google/technology/ai/rss/',
      categoryCode: 'industry',
    ),
    AiNewsSourceConfig(
      id: 'arxiv_cs_ai',
      name: 'arXiv cs.AI',
      feedUrl: 'https://rss.arxiv.org/rss/cs.AI',
      categoryCode: 'paper',
    ),
    // BestBlogs.dev:AI 初评 + 编辑精审的中文精选池,官方公开 RSS
    // (README 明确提供订阅端点与参数,2026-07-16 核验可用)。
    // 只取 AI 分类的精选内容,避免全站流量淹没时间线。
    AiNewsSourceConfig(
      id: 'bestblogs_ai_featured',
      name: 'BestBlogs 精选',
      feedUrl: 'https://www.bestblogs.dev/feeds/rss?category=ai&featured=y',
      categoryCode: 'tip',
    )
  ];
}
