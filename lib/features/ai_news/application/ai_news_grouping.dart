import '../domain/ai_news_item.dart';

/* 
*按发布日期(本地时区)对条目分组,保持 API 给出的倒序。
*publishedAt 以 UTC 存储,转本地时区后再按天聚合,
*否则凌晨前后的 UTC 日期会与用户感知的「今天」错位。
*/
List<MapEntry<DateTime, List<AiNewsItem>>> groupAiNewsByDay(List<AiNewsItem> items) {
  final map = <String, List<AiNewsItem>>{};
  for (final item in items) {
    final d = item.publishedAt.toLocal();
    final key = '${d.year}-${d.month}-${d.day}';
    map.putIfAbsent(key, () => []).add(item);
  }
  return map.entries.map((e) {
    final parts = e.key.split('-');
    return MapEntry(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])), e.value);
  }).toList();
}
