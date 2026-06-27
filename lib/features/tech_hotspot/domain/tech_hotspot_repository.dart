import 'tech_hotspot_models.dart';

/// 技术热点数据仓库。
///
/// 当前实现读取本地模拟数据,后续可替换为远端 API + 缓存。
abstract interface class TechHotspotRepository {
  TechHotspotDigest getDigest();
}
