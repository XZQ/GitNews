import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';
import 'mock_tech_hotspot.dart';

/// 基于本地模拟数据的技术热点仓库。
class LocalTechHotspotRepository implements TechHotspotRepository {
  const LocalTechHotspotRepository();

  @override
  TechHotspotDigest getDigest() {
    return const TechHotspotDigest(
      languages: MockTechHotspot.languages,
      topics: MockTechHotspot.topics,
      heatTrend: MockTechHotspot.heatTrend,
      hotTags: MockTechHotspot.hotTags,
    );
  }
}
