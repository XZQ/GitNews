import 'ai_news_item.dart';

/// AI 动态数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为远端 API + 缓存。
abstract interface class AiNewsRepository {
  AiNewsDigest getDigest();
}
