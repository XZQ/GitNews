import 'package:xml/xml.dart';

import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';
import 'feed_date_parser.dart';

export 'feed_date_parser.dart';

/*
*RSS 2.0 / Atom feed 解析器(纯函数,便于单测)。
*把补充源条目直接映射为 [AiNewsItem]:
*- AI HOT RSS 优先用 guid 作 id,与 REST id 同一空间
*- category:优先条目 category,回退源配置默认分类
*- author/content:encoded:解析并以安全纯文本进入领域模型
*- AI HOT 条目 link 作 permalink,description 中的“阅读原文”作 url
*- summary:剥离 HTML 标签并截断
*- publishedAt:统一转 UTC;缺失时用 [fallbackTime]
*/
List<AiNewsItem> parseAiNewsFeed(String xmlText, {required AiNewsSourceConfig source, required DateTime fallbackTime}) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlText);
  } on XmlException catch (e, st) {
    throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st, meta: {'source': source.id});
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
  final channelDate = parseFeedDate(_text(channel, 'pubDate')) ?? parseFeedDate(_text(channel, 'lastBuildDate')) ?? fallback;
  final items = <AiNewsItem>[];
  for (final node in channel.findElements('item')) {
    final link = _text(node, 'link');
    final title = _cleanText(_text(node, 'title'));
    if (link.isEmpty || title.isEmpty) {
      continue;
    }
    final publishedAt = parseFeedDate(_text(node, 'pubDate')) ?? parseFeedDate(_text(node, 'date')) ?? channelDate;
    final description = _text(node, 'description');
    final guid = _text(node, 'guid');
    final author = _text(node, 'author').isNotEmpty ? _text(node, 'author') : _text(node, 'creator');
    final content = _text(node, 'encoded');
    final category = _rssCategory(node);
    final permalink = link.trim();
    final originalUrl = source.usesAiHotContract ? (_extractOriginalUrl(description) ?? permalink) : permalink;
    items.add(
      _buildItem(
        source: source,
        title: title,
        link: originalUrl,
        permalink: permalink,
        guid: guid,
        author: author,
        content: content,
        categoryCode: category,
        summary: description,
        publishedAt: publishedAt,
      ),
    );
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
    final publishedAt = parseFeedDate(_text(node, 'published')) ?? parseFeedDate(_text(node, 'updated')) ?? fallback;
    final summary = _text(node, 'summary');
    final content = _text(node, 'content');
    items.add(
      _buildItem(
        source: source,
        title: title,
        link: link,
        permalink: link,
        guid: _text(node, 'id'),
        author: _atomAuthor(node),
        content: content,
        categoryCode: _atomCategory(node),
        summary: summary.isNotEmpty ? summary : content,
        publishedAt: publishedAt,
      ),
    );
  }
  return items;
}

AiNewsItem _buildItem({
  required AiNewsSourceConfig source,
  required String title,
  required String link,
  required String permalink,
  required String guid,
  required String author,
  required String content,
  required String categoryCode,
  required String summary,
  required DateTime publishedAt,
}) {
  final stableIdentity = guid.trim().isNotEmpty ? guid.trim() : link;
  final id = source.usesAiHotContract && guid.trim().isNotEmpty ? guid.trim() : 'rss:${source.id}:${fnv1aHex(stableIdentity)}';
  return AiNewsItem(
    id: id,
    category: _categoryFromFeed(categoryCode) ?? AiNewsCategory.fromCode(source.categoryCode) ?? AiNewsCategory.industry,
    title: title,
    // 补充源均为英文源:主标题即原文,不重复占用副标题位。
    titleEn: '',
    summary: _truncate(_cleanText(summary), 600),
    source: _sourceName(author, source.name),
    url: link,
    permalink: permalink,
    publishedAt: publishedAt.toUtc(),
    score: 0,
    selected: source.usesAiHotContract,
    author: author.trim(),
    content: _truncate(_cleanText(content), 8000),
    attributionSource: source.usesAiHotContract ? 'AI HOT' : '',
  );
}

String _rssCategory(XmlElement item) {
  for (final child in item.childElements) {
    if (child.name.local == 'category') {
      return child.innerText.trim();
    }
  }
  return '';
}

String _atomCategory(XmlElement entry) {
  for (final child in entry.childElements) {
    if (child.name.local == 'category') {
      return child.getAttribute('term')?.trim() ?? child.innerText.trim();
    }
  }
  return '';
}

String _atomAuthor(XmlElement entry) {
  for (final child in entry.childElements) {
    if (child.name.local != 'author') {
      continue;
    }
    return _text(child, 'name').isNotEmpty ? _text(child, 'name') : child.innerText.trim();
  }
  return '';
}

AiNewsCategory? _categoryFromFeed(String raw) {
  final normalized = raw.trim().toLowerCase();
  final direct = AiNewsCategory.fromCode(normalized);
  if (direct != null) {
    return direct;
  }
  return switch (normalized) {
    '模型发布/更新' || '模型' => AiNewsCategory.aiModels,
    '产品发布/更新' || '产品' => AiNewsCategory.aiProducts,
    '论文研究' || '论文' => AiNewsCategory.paper,
    '技巧观点' || '技巧与观点' || '技巧' => AiNewsCategory.tip,
    '行业动态' || '行业' => AiNewsCategory.industry,
    _ => null,
  };
}

String _sourceName(String author, String fallback) {
  final trimmed = author.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }
  final match = RegExp(r'\((.+)\)$').firstMatch(trimmed);
  return match?.group(1)?.trim().isNotEmpty == true ? match!.group(1)!.trim() : trimmed;
}

String? _extractOriginalUrl(String description) {
  final text = _cleanText(description);
  final match = RegExp(r'(?:阅读原文|原文|Original)\s*[:：]?\s*(https?://[^\s]+)', caseSensitive: false).firstMatch(text);
  return match?.group(1)?.replaceFirst(RegExp(r'[。，,;)]]+$'), '');
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
