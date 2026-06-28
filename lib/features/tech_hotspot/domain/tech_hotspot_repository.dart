import 'tech_hotspot_models.dart';

/// 技术趋势数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为远端 API + 缓存。
abstract interface class TechHotspotRepository {
  TechHotspotDigest getDigest();

  /// 按 id 查询单个主题;未找到返回 null。
  TechTopic? getById(String id);

  /// 全量主题列表。
  List<TechTopic> allTopics();
}
