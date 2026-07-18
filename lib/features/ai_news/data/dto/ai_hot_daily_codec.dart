import '../../domain/ai_hot_daily.dart';
import 'ai_hot_json.dart';

/*
*AI HOT 日报与日期索引 JSON codec。
*/
class AiHotDailyCodec {
  const AiHotDailyCodec._();

  /* 解码完整日报。 */
  static AiHotDailyReport report(Map<String, Object?> json) {
    return AiHotDailyReport(
      date: AiHotJson.string(json['date']),
      generatedAt: AiHotJson.date(json['generatedAt']),
      windowStart: AiHotJson.date(json['windowStart']),
      windowEnd: AiHotJson.date(json['windowEnd']),
      lead: _lead(json['lead']),
      sections: _sections(json['sections']),
      flashes: _flashes(json['flashes']),
      attribution: AiHotJson.attribution(json['attribution']),
    );
  }

  /* 解码日报索引页并返回条目。 */
  static List<AiHotDailyEntry> entries(Map<String, Object?> json) {
    final raw = json['items'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (AiHotJson.object(item) case final Map<String, Object?> value)
          AiHotDailyEntry(
            date: AiHotJson.string(value['date']),
            generatedAt: AiHotJson.date(value['generatedAt']),
            leadTitle: AiHotJson.nullableString(value['leadTitle']),
            leadParagraph: AiHotJson.nullableString(value['leadParagraph']),
            attribution: AiHotJson.attribution(value['attribution']),
          ),
    ];
  }

  static AiHotDailyLead? _lead(Object? raw) {
    final json = AiHotJson.object(raw);
    if (json == null) {
      return null;
    }
    final title = AiHotJson.string(json['title']).trim();
    final paragraph = AiHotJson.string(json['leadParagraph']).trim();
    if (title.isEmpty && paragraph.isEmpty) {
      return null;
    }
    return AiHotDailyLead(title: title, paragraph: paragraph);
  }

  static List<AiHotDailySection> _sections(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final section in raw)
        if (AiHotJson.object(section) case final Map<String, Object?> value)
          AiHotDailySection(
            label: AiHotJson.string(value['label']),
            items: _items(value['items']),
          ),
    ];
  }

  static List<AiHotDailyItem> _items(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (AiHotJson.object(item) case final Map<String, Object?> value)
          AiHotDailyItem(
            title: AiHotJson.string(value['title']),
            summary: AiHotJson.string(value['summary']),
            sourceUrl: AiHotJson.string(value['sourceUrl']),
            sourceName: AiHotJson.string(value['sourceName']),
            permalink: AiHotJson.nullableString(value['permalink']),
            attribution: AiHotJson.attribution(value['attribution']),
          ),
    ];
  }

  static List<AiHotDailyFlash> _flashes(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (AiHotJson.object(item) case final Map<String, Object?> value)
          AiHotDailyFlash(
            title: AiHotJson.string(value['title']),
            sourceName: AiHotJson.string(value['sourceName']),
            sourceUrl: AiHotJson.string(value['sourceUrl']),
            publishedAt: AiHotJson.date(value['publishedAt']),
            permalink: AiHotJson.nullableString(value['permalink']),
            attribution: AiHotJson.attribution(value['attribution']),
          ),
    ];
  }
}
