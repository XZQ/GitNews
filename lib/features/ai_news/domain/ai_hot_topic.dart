/*
*AI HOT 当前热点。
*与按发布时间排序的资讯流分离,表达近期多信源讨论强度。
*/
class AiHotTopic {
  const AiHotTopic({
    required this.id,
    required this.title,
    required this.url,
    required this.permalink,
    required this.source,
    required this.sourceCount,
    required this.signalCount,
    required this.sourceNames,
    required this.latestAt,
  });

  // 与 items API 共用的主条目 ID。
  final String id;

  // 热点标题。
  final String title;

  // 第三方原文链接。
  final String url;

  // AI HOT 站内阅读链接。
  final String permalink;

  // 展示主条的来源。
  final String source;

  // 窗口内独立报道信源数。
  final int sourceCount;

  // 窗口内独立纯热点信号组数。
  final int signalCount;

  // 去重后的信源名。
  final List<String> sourceNames;

  // 窗口内最新报道时间。
  final DateTime latestAt;
}
