import 'tech_hotspot_models.dart';

/* AI 雷达数据仓库。 */
/*  */
/* 当前实现默认读取 GitHub Search 聚合结果并使用本地快照缓存;远端失败时可 */
/* 回退过期缓存或本地种子数据。 */
/*  */
/* 接口统一 `Future<T>`(CLAUDE.md §六),与 trending / monitor / repo_detail 保持一致。 */
abstract interface class TechHotspotRepository {
  Future<TechHotspotDigest> getDigest();

  /* 按 id 查询单个主题;未找到返回 null。 */
  Future<TechTopic?> getById(String id);

  /* 全量主题列表。 */
  Future<List<TechTopic>> allTopics();
}
