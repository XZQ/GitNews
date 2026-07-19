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
  const AiNewsItem({
    required this.id,
    required this.category,
    required this.title,
    required this.titleEn,
    required this.summary,
    required this.source,
    required this.url,
    required this.permalink,
    required this.publishedAt,
    required this.score,
    required this.selected,
    this.author = '',
    this.content = '',
    this.attributionSource = '',
  });

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

  // RSS author 或条目作者标识。
  final String author;

  // 从 content:encoded/Atom content 提取的安全纯文本正文。
  final String content;

  // 聚合方署名;原文作者和来源仍由 [author]/[source] 表达。
  final String attributionSource;

  /*
  *按语言返回资讯标题。
  *中文环境优先 [title],其余语言默认 [titleEn];首选字段为空时回退到另一字段。
  */
  String titleForLanguage(String? languageCode) {
    final chineseTitle = title.trim();
    final englishTitle = titleEn.trim();
    if (languageCode?.trim().toLowerCase().startsWith('zh') ?? false) {
      return chineseTitle.isNotEmpty ? chineseTitle : englishTitle;
    }
    return englishTitle.isNotEmpty ? englishTitle : chineseTitle;
  }

  /* 复制条目,用于 REST 主条目吸收 RSS 补充字段。 */
  AiNewsItem copyWith({
    String? id,
    AiNewsCategory? category,
    String? title,
    String? titleEn,
    String? summary,
    String? source,
    String? url,
    String? permalink,
    DateTime? publishedAt,
    int? score,
    bool? selected,
    String? author,
    String? content,
    String? attributionSource,
  }) {
    return AiNewsItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      summary: summary ?? this.summary,
      source: source ?? this.source,
      url: url ?? this.url,
      permalink: permalink ?? this.permalink,
      publishedAt: publishedAt ?? this.publishedAt,
      score: score ?? this.score,
      selected: selected ?? this.selected,
      author: author ?? this.author,
      content: content ?? this.content,
      attributionSource: attributionSource ?? this.attributionSource,
    );
  }
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
