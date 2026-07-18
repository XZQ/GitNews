import 'ai_hot_attribution.dart';

/*
*AI HOT 官方日报的导语。
*/
class AiHotDailyLead {
  const AiHotDailyLead({required this.title, required this.paragraph});

  // 导语标题。
  final String title;

  // 导语正文。
  final String paragraph;
}

/*
*日报分类内的单条精选。
*/
class AiHotDailyItem {
  const AiHotDailyItem({
    required this.title,
    required this.summary,
    required this.sourceUrl,
    required this.sourceName,
    this.permalink,
    this.attribution,
  });

  // 精选标题。
  final String title;

  // 中文摘要。
  final String summary;

  // 第三方原文链接。
  final String sourceUrl;

  // 第三方来源名。
  final String sourceName;

  // AI HOT 站内阅读链接。
  final String? permalink;

  // 可选 AI HOT 署名。
  final AiHotAttribution? attribution;
}

/*
*日报内的分类区块。
*/
class AiHotDailySection {
  const AiHotDailySection({required this.label, required this.items});

  // 中文分类名。
  final String label;

  // 该分类精选条目。
  final List<AiHotDailyItem> items;
}

/*
*日报快讯条目。
*/
class AiHotDailyFlash {
  const AiHotDailyFlash({
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    required this.publishedAt,
    this.permalink,
    this.attribution,
  });

  // 快讯标题。
  final String title;

  // 第三方来源名。
  final String sourceName;

  // 第三方原文链接。
  final String sourceUrl;

  // 快讯发布时间。
  final DateTime? publishedAt;

  // AI HOT 站内阅读链接。
  final String? permalink;

  // 可选 AI HOT 署名。
  final AiHotAttribution? attribution;
}

/*
*AI HOT 某一日的完整官方日报。
*/
class AiHotDailyReport {
  const AiHotDailyReport({
    required this.date,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.sections,
    required this.flashes,
    this.lead,
    this.attribution,
  });

  // YYYY-MM-DD 日报日期。
  final String date;

  // 报告生成时间。
  final DateTime? generatedAt;

  // 统计窗口开始。
  final DateTime? windowStart;

  // 统计窗口结束。
  final DateTime? windowEnd;

  // 可选导语。
  final AiHotDailyLead? lead;

  // 精选分类区块。
  final List<AiHotDailySection> sections;

  // 快讯列表。
  final List<AiHotDailyFlash> flashes;

  // 日报署名与 canonical。
  final AiHotAttribution? attribution;

  int get itemCount => sections.fold<int>(0, (count, section) => count + section.items.length) + flashes.length;
}

/*
*最近日报索引条目。
*/
class AiHotDailyEntry {
  const AiHotDailyEntry({
    required this.date,
    required this.generatedAt,
    this.leadTitle,
    this.leadParagraph,
    this.attribution,
  });

  // YYYY-MM-DD 日期。
  final String date;

  // 报告生成时间。
  final DateTime? generatedAt;

  // 可选主编标题。
  final String? leadTitle;

  // 可选主编导语。
  final String? leadParagraph;

  // 日报署名与 canonical。
  final AiHotAttribution? attribution;
}
