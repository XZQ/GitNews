import '../domain/ai_news_item.dart';

/*
*多源条目合并与去重。
*
*身份优先级:id(RSS guid = REST id) → AI HOT permalink → 第三方原文 URL → 规范化标题。
*REST 主条目优先保留,但会吸收 RSS author/content:encoded 等补充字段。
*/
List<AiNewsItem> mergeAiNewsItems({required List<AiNewsItem> primary, required List<List<AiNewsItem>> extras}) {
  final indexes = <String, int>{};
  final merged = <AiNewsItem>[];

  void add(AiNewsItem item) {
    final keys = _identityKeys(item);
    int? duplicateIndex;
    for (final key in keys) {
      duplicateIndex ??= indexes[key];
    }
    if (duplicateIndex != null) {
      final enriched = _enrich(merged[duplicateIndex], item);
      merged[duplicateIndex] = enriched;
      for (final key in _identityKeys(enriched)) {
        indexes[key] = duplicateIndex;
      }
      return;
    }
    final index = merged.length;
    merged.add(item);
    for (final key in keys) {
      indexes[key] = index;
    }
  }

  primary.forEach(add);
  for (final items in extras) {
    items.forEach(add);
  }
  merged.sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
  return merged;
}

List<String> _identityKeys(AiNewsItem item) {
  final id = item.id.trim();
  final permalink = normalizeAiNewsUrl(item.permalink);
  final originalUrl = normalizeAiNewsUrl(item.url);
  final title = normalizeAiNewsTitle(item.titleEn.isNotEmpty ? item.titleEn : item.title);
  return [
    if (id.isNotEmpty) 'id:$id',
    if (permalink.isNotEmpty) 'permalink:$permalink',
    if (originalUrl.isNotEmpty) 'url:$originalUrl',
    if (title.isNotEmpty) 'title:$title',
  ];
}

AiNewsItem _enrich(AiNewsItem primary, AiNewsItem supplement) {
  return primary.copyWith(
    titleEn: primary.titleEn.isNotEmpty ? primary.titleEn : supplement.titleEn,
    summary: primary.summary.isNotEmpty ? primary.summary : supplement.summary,
    source: primary.source.isNotEmpty ? primary.source : supplement.source,
    url: primary.url.isNotEmpty ? primary.url : supplement.url,
    permalink: primary.permalink.isNotEmpty ? primary.permalink : supplement.permalink,
    author: primary.author.isNotEmpty ? primary.author : supplement.author,
    content: primary.content.isNotEmpty ? primary.content : supplement.content,
    attributionSource: primary.attributionSource.isNotEmpty ? primary.attributionSource : supplement.attributionSource,
  );
}

/*
*URL 规范化:小写 scheme/host、去 fragment、去追踪参数与尾部斜杠。
*/
String normalizeAiNewsUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) {
    return trimmed.toLowerCase();
  }
  final query = <String, String>{
    for (final entry in uri.queryParameters.entries)
      if (!entry.key.toLowerCase().startsWith('utm_') && entry.key.toLowerCase() != 'ref' && entry.key.toLowerCase() != 'source') entry.key: entry.value,
  };
  var path = uri.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: path,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
}

/* 标题规范化:小写后仅保留中英文与数字;过短标题不参与去重。 */
String normalizeAiNewsTitle(String raw) {
  final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9一-鿿]+'), '');
  return normalized.length < 8 ? '' : normalized;
}
