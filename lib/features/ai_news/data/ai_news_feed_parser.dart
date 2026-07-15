import 'package:xml/xml.dart';

import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';

/*
*RSS 2.0 / Atom feed 解析器(纯函数,便于单测)。
*把补充源条目直接映射为 [AiNewsItem]:
*- id:`rss:<sourceId>:<fnv1a(link)>`,内容寻址、跨次拉取稳定
*- category:取源配置的默认分类
*- summary:剥离 HTML 标签并截断
*- publishedAt:统一转 UTC;缺失时用 [fallbackTime]
*/
List<AiNewsItem> parseAiNewsFeed(String xmlText, {required AiNewsSourceConfig source, required DateTime fallbackTime}) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlText);
  } on XmlException catch (e, st) {
    throw AppException(
      kind: AppExceptionKind.parse,
      cause: e,
      stack: st,
      meta: {'source': source.id},
    );
  }
  final root = doc.rootElement;
  final fallbackUtc = fallbackTime.toUtc();
  if (root.name.local == 'rss') {
    return _parseRss(root, source, fallbackUtc);
  }
  if (root.name.local == 'feed') {
    return _parseAtom(root, source, fallbackUtc);
  }
  throw AppException(kind: AppExceptionKind.parse, meta: {'source': source.id, 'root': root.name.local});
}

List<AiNewsItem> _parseRss(XmlElement rss, AiNewsSourceConfig source, DateTime fallback) {
  final channel = rss.getElement('channel');
  if (channel == null) {
    return const [];
  }
  // 条目缺日期时优先用 channel 级日期,最后才是调用方给的 fallback。
  final channelDate = _parseFeedDate(_text(channel, 'pubDate')) ?? _parseFeedDate(_text(channel, 'lastBuildDate')) ?? fallback;
  final items = <AiNewsItem>[];
  for (final node in channel.findElements('item')) {
    final link = _text(node, 'link');
    final title = _cleanText(_text(node, 'title'));
    if (link.isEmpty || title.isEmpty) {
      continue;
    }
    final publishedAt = _parseFeedDate(_text(node, 'pubDate')) ?? _parseFeedDate(_text(node, 'date')) ?? channelDate;
    items.add(_buildItem(
      source: source,
      title: title,
      link: link.trim(),
      summary: _text(node, 'description'),
      publishedAt: publishedAt,
    ));
  }
  return items;
}

List<AiNewsItem> _parseAtom(XmlElement feed, AiNewsSourceConfig source, DateTime fallback) {
  final items = <AiNewsItem>[];
  for (final node in feed.findElements('entry')) {
    final link = _atomLink(node);
    final title = _cleanText(_text(node, 'title'));
    if (link.isEmpty || title.isEmpty) {
      continue;
    }
    final publishedAt = _parseFeedDate(_text(node, 'published')) ?? _parseFeedDate(_text(node, 'updated')) ?? fallback;
    final summary = _text(node, 'summary');
    items.add(_buildItem(
      source: source,
      title: title,
      link: link,
      summary: summary.isNotEmpty ? summary : _text(node, 'content'),
      publishedAt: publishedAt,
    ));
  }
  return items;
}

AiNewsItem _buildItem({
  required AiNewsSourceConfig source,
  required String title,
  required String link,
  required String summary,
  required DateTime publishedAt,
}) {
  return AiNewsItem(
    id: 'rss:${source.id}:${fnv1aHex(link)}',
    category: AiNewsCategory.fromCode(source.categoryCode) ?? AiNewsCategory.industry,
    title: title,
    // 补充源均为英文源:主标题即原文,不重复占用副标题位。
    titleEn: '',
    summary: _truncate(_cleanText(summary), 600),
    source: source.name,
    url: link,
    permalink: link,
    publishedAt: publishedAt.toUtc(),
    score: 0,
    selected: false,
  );
}

// Atom 的 link 是元素属性:优先 rel=alternate,退回第一个带 href 的 link。
String _atomLink(XmlElement entry) {
  String fallback = '';
  for (final link in entry.findElements('link')) {
    final href = link.getAttribute('href')?.trim() ?? '';
    if (href.isEmpty) {
      continue;
    }
    final rel = link.getAttribute('rel');
    if (rel == null || rel == 'alternate') {
      return href;
    }
    if (fallback.isEmpty) {
      fallback = href;
    }
  }
  return fallback;
}

// 取子元素文本(忽略命名空间前缀,如 dc:date 也能被 'date' 命中)。
String _text(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.name.local == localName) {
      return child.innerText.trim();
    }
  }
  return '';
}

// 剥掉 HTML 标签、解码常见实体、折叠空白。
String _cleanText(String raw) {
  var s = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
  const entities = {'&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'", '&apos;': "'", '&nbsp;': ' '};
  entities.forEach((k, v) => s = s.replaceAll(k, v));
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _truncate(String s, int max) {
  if (s.length <= max) {
    return s;
  }
  return '${s.substring(0, max)}…';
}

/*
*解析 feed 日期:先试 ISO-8601(Atom),再试 RFC-822(RSS)。
*返回 UTC;解析失败返回 null 由调用方兜底。
*/
DateTime? _parseFeedDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return null;
  }
  final iso = DateTime.tryParse(s);
  if (iso != null) {
    return iso.toUtc();
  }
  return parseRfc822Date(s);
}

const Map<String, int> _kMonths = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, // -
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
};

/*
*RFC-822 日期解析(RSS pubDate),如 `Sat, 18 Apr 2026 00:00:00 -0400`。
*支持数字时区偏移与 GMT/UT/UTC/Z;其他命名时区按 UTC 处理(误差可接受,
*资讯按天分组展示)。无法解析返回 null。
*/
DateTime? parseRfc822Date(String raw) {
  final match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\w*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{1,4})?').firstMatch(raw);
  if (match == null) {
    return null;
  }
  final month = _kMonths[match.group(2)!.toLowerCase()];
  if (month == null) {
    return null;
  }
  var year = int.parse(match.group(3)!);
  if (year < 100) {
    year += year >= 70 ? 1900 : 2000;
  }
  final utc = DateTime.utc(
    year,
    month,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6) ?? '0'),
  );
  final zone = match.group(7) ?? '';
  final numeric = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
  if (numeric == null) {
    // GMT/UT/UTC/Z 及未知命名时区一律按 UTC。
    return utc;
  }
  final sign = numeric.group(1) == '-' ? -1 : 1;
  final offset = Duration(hours: int.parse(numeric.group(2)!), minutes: int.parse(numeric.group(3)!));
  return utc.subtract(offset * sign);
}

/*
*FNV-1a 32-bit 哈希(hex)。用于给 RSS 条目生成稳定 id;
*不用 `String.hashCode` 是因为它不保证跨运行稳定。
*/
String fnv1aHex(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
