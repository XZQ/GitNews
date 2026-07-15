import '../../domain/ai_news_item.dart';

/* 
*`/api/public/items` 单条响应 DTO。
*/
class AiNewsItemDto {
  const AiNewsItemDto(
      {required this.id,
      required this.title,
      required this.titleEn,
      required this.url,
      required this.permalink,
      required this.source,
      required this.publishedAt,
      required this.summary,
      required this.category,
      required this.score,
      required this.selected});

  factory AiNewsItemDto.fromJson(Map<String, Object?> json) {
    return AiNewsItemDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      url: json['url'] as String? ?? '',
      permalink: json['permalink'] as String? ?? '',
      source: json['source'] as String? ?? '',
      publishedAt: _parseTime(json['publishedAt']),
      summary: json['summary'] as String? ?? '',
      category: json['category'] as String? ?? 'industry',
      score: (json['score'] as num?)?.toInt() ?? 0,
      selected: json['selected'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String titleEn;
  final String url;
  final String permalink;
  final String source;
  final DateTime publishedAt;
  final String summary;
  final String category;
  final int score;
  final bool selected;

  AiNewsItem toDomain() {
    final cat = AiNewsCategory.fromCode(category) ?? AiNewsCategory.industry;
    return AiNewsItem(
      id: id,
      category: cat,
      title: title,
      titleEn: titleEn,
      summary: summary,
      source: source,
      url: url,
      permalink: permalink,
      publishedAt: publishedAt,
      score: score,
      selected: selected,
    );
  }

  static DateTime _parseTime(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/* 
*`/api/public/items` 顶层响应 DTO。
*/
class AiNewsListResponseDto {
  const AiNewsListResponseDto({
    required this.count,
    required this.hasNext,
    required this.items,
    this.nextCursor,
  });

  factory AiNewsListResponseDto.fromJson(Map<String, Object?> json) {
    final list = json['items'];
    return AiNewsListResponseDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
      items: list is List ? list.whereType<Map<String, Object?>>().map(AiNewsItemDto.fromJson).toList(growable: false) : const [],
    );
  }

  final int count;
  final bool hasNext;
  final String? nextCursor;
  final List<AiNewsItemDto> items;

  AiNewsDigest toDomain() => AiNewsDigest(
        items: items.map((e) => e.toDomain()).toList(growable: false),
        count: count,
        hasNext: hasNext,
        nextCursor: nextCursor,
      );
}
