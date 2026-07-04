import 'tech_hotspot_models.dart';

/// AI 雷达数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为远端 API + 缓存。
///
/// 接口统一 `Future<T>`(CLAUDE.md §六),与 trending / monitor / repo_detail 保持一致。
abstract interface class TechHotspotRepository {
  Future<TechHotspotDigest> getDigest();

  /// 按 id 查询单个主题;未找到返回 null。
  Future<TechTopic?> getById(String id);

  /// 全量主题列表。
  Future<List<TechTopic>> allTopics();
}
