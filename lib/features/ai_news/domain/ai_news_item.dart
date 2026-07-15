// AI 动态领域模型(纯 Dart)。
// 字段对齐 `https://aihot.virxact.com/api/public/items` 的真实响应。
library;

/* 
*AI 动态分类。对应 API 的 `category` 字段。
*5 个分类正好对应参考站底部 5 栏导航。
*/
enum AiNewsCategory {
  // 新模型 / 模型版本更新。
  aiModels('ai-models', '模型'),

  // AI 产品 / 应用 / 功能更新。
  aiProducts('ai-products', '产品'),

  // 论文 / 研究 / 基准测试。
  paper('paper', '论文'),

  // 技巧 / 教程 / 工程实践。
  tip('tip', '技巧'),

  // 行业动态 / 公司战略 / 投融资。
  industry('industry', '行业');

  const AiNewsCategory(this.code, this.label);

  // API 接口的字符串编码。
  final String code;

  // 中文展示标签。
  final String label;

  /* 
  *从 API `category` 字符串反查枚举;未匹配返回 null。
  */
  static AiNewsCategory? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final c in values) {
      if (c.code == code) {
        return c;
      }
    }
    return null;
  }
}

/* 
*AI 动态条目。
*/
class AiNewsItem {
  const AiNewsItem(
      {required this.id,
      required this.category,
      required this.title,
      required this.titleEn,
      required this.summary,
      required this.source,
      required this.url,
      required this.permalink,
      required this.publishedAt,
      required this.score,
      required this.selected});

  final String id;
  final AiNewsCategory category;
  final String title;
  final String titleEn;
  final String summary;
  final String source;
  final String url;
  final String permalink;
  final DateTime publishedAt;
  final int score;
  final bool selected;
}

/* 
*一次拉取的页面结果。
*/
class AiNewsDigest {
  const AiNewsDigest({required this.items, required this.count, required this.hasNext, this.nextCursor});

  final List<AiNewsItem> items;
  final int count;
  final bool hasNext;
  final String? nextCursor;
}
