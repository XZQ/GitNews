import 'ai_news_item.dart';

/* 
*AI 动态数据仓库。
*远端实现:`RemoteAiNewsRepository` → `https://aihot.virxact.com/api/public/items`。
*/
abstract interface class AiNewsRepository {
  /* 
  *拉取条目列表。
  *- [category]:为 null 时返回全部分类;否则服务端按 `?category=<code>` 过滤
  *- [since]:ISO-8601 时间窗起点
  *- [query]:关键词(服务端 ILIKE)
  *- [cursor]:分页游标(上一页返回的 [AiNewsDigest.nextCursor])
  *- [selectedOnly]:true=仅精选(默认);false=`mode=all`
  */
  Future<AiNewsDigest> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  });
}
