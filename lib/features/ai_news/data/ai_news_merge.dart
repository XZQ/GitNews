import '../domain/ai_news_item.dart';

/*
*多源条目合并与去重(纯函数,便于单测)。
*去重键:规范化 URL 或规范化标题命中任一即视为同一事件;
*主源(精选流,含中文标题与热度分)优先于补充 RSS 源保留。
*/
List<AiNewsItem> mergeAiNewsItems({required List<AiNewsItem> primary, required List<List<AiNewsItem>> extras}) {
  final seenUrls = <String>{};
  final seenTitles = <String>{};
  final merged = <AiNewsItem>[];

  void add(AiNewsItem item) {
    final url = normalizeAiNewsUrl(item.url.isNotEmpty ? item.url : item.permalink);
    final title = normalizeAiNewsTitle(item.titleEn.isNotEmpty ? item.titleEn : item.title);
    final urlDup = url.isNotEmpty && !seenUrls.add(url);
    final titleDup = title.isNotEmpty && !seenTitles.add(title);
    if (urlDup || titleDup) {
      return;
    }
    merged.add(item);
  }

  primary.forEach(add);
  for (final list in extras) {
    list.forEach(add);
  }
  merged.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  return merged;
}

/*
*URL 规范化:小写 scheme/host、去 fragment、去追踪参数(utm_* / ref /
*source)、去尾部斜杠。解析失败返回原始字符串的小写形式。
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
      if (!entry.key.startsWith('utm_') && entry.key != 'ref' && entry.key != 'source') entry.key: entry.value
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

/*
*标题规范化:小写后仅保留中英文与数字,用于跨源近似匹配。
*过短(<8 个有效字符)的标题不参与标题去重,避免误伤。
*/
String normalizeAiNewsTitle(String raw) {
  final s = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9一-鿿]+'), '');
  return s.length < 8 ? '' : s;
}
