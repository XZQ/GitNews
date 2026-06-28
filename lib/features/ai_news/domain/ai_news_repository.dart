import 'ai_news_item.dart';

/// AI 动态数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为远端 API + 缓存。
abstract interface class AiNewsRepository {
  AiNewsDigest getDigest();

  /// 按 id 查询单条动态;未找到返回 null。
  AiNewsItem? getById(String id);

  /// 全量动态列表。
  List<AiNewsItem> all();
}
