import 'ai_news_item.dart';

enum AiNewsReadFilter { all, unread, read }

/*
*资讯库检索过滤器。日期采用半开区间 [publishedAfter, publishedBefore)，
*便于按自然日和预设时间窗口组合。
*/
class AiNewsLibraryFilter {
  const AiNewsLibraryFilter({
    this.category,
    this.source,
    this.publishedAfter,
    this.publishedBefore,
    this.read = AiNewsReadFilter.all,
  });

  final AiNewsCategory? category;
  final String? source;
  final DateTime? publishedAfter;
  final DateTime? publishedBefore;
  final AiNewsReadFilter read;

  bool get isActive => source != null || publishedAfter != null || publishedBefore != null || read != AiNewsReadFilter.all;

  AiNewsLibraryFilter copyWith({
    AiNewsCategory? category,
    String? source,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
    AiNewsReadFilter? read,
    bool clearCategory = false,
    bool clearSource = false,
    bool clearPublishedAfter = false,
    bool clearPublishedBefore = false,
  }) {
    return AiNewsLibraryFilter(
      category: clearCategory ? null : (category ?? this.category),
      source: clearSource ? null : (source ?? this.source),
      publishedAfter: clearPublishedAfter ? null : (publishedAfter ?? this.publishedAfter),
      publishedBefore: clearPublishedBefore ? null : (publishedBefore ?? this.publishedBefore),
      read: read ?? this.read,
    );
  }
}
