/// AI 资讯领域模型(纯 Dart)。
///
/// 用于 [AiNewsPage] 的展示数据。当前由 mock 提供,
/// 接入真实数据源后替换为 Repository。
library;

/// AI 资讯分类。覆盖信息流的 4 个核心维度。
enum AiNewsCategory {
  /// 行业动态:大公司战略、政策、人事情报。
  industry,

  /// 技术突破:新模型、新论文、新算法。
  breakthrough,

  /// 产业应用:垂直行业落地案例(B 端 / C 端)。
  application,

  /// 投融资:融资、收购、IPO。
  funding,
}

/// AI 资讯条目。
class AiNewsItem {
  const AiNewsItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.source,
    required this.author,
    required this.publishedAt,
    required this.readMinutes,
    required this.reads,
    required this.likes,
    required this.tags,
    required this.isHero,
    this.coverColor = 0xFF6E56CF,
  });

  final String id;
  final AiNewsCategory category;
  final String title;
  final String summary;
  final String source;
  final String author;
  final DateTime publishedAt;
  final int readMinutes;
  final int reads;
  final int likes;
  final List<String> tags;
  final bool isHero;
  final int coverColor;
}
