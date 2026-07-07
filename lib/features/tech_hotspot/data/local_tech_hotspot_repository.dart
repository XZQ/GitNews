import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';
import 'tech_hotspot_seed_data.dart';

/* 基于内置种子数据的 AI 雷达仓库。 */
class LocalTechHotspotRepository implements TechHotspotRepository {
  const LocalTechHotspotRepository();

  @override
  Future<TechHotspotDigest> getDigest() async {
    return const TechHotspotDigest(
      languages: TechHotspotSeedData.languages,
      topics: TechHotspotSeedData.topics,
      heatTrend: TechHotspotSeedData.heatTrend,
      hotTags: TechHotspotSeedData.hotTags,
    );
  }

  @override
  Future<TechTopic?> getById(String id) async =>
      TechHotspotSeedData.topics.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<TechTopic>> allTopics() async => TechHotspotSeedData.topics;
}
