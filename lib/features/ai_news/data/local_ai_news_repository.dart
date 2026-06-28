import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';
import 'mock_ai_news.dart';

/// 基于本地模拟数据的 AI 动态仓库。
class LocalAiNewsRepository implements AiNewsRepository {
  const LocalAiNewsRepository();

  @override
  AiNewsDigest getDigest() {
    return AiNewsDigest(
      items: MockAiNews.all,
      hotTopics: MockAiNews.hotTopics,
      topCompanies: MockAiNews.topCompanies,
    );
  }

  @override
  AiNewsItem? getById(String id) =>
      MockAiNews.all.where((e) => e.id == id).firstOrNull;

  @override
  List<AiNewsItem> all() => MockAiNews.all;
}
