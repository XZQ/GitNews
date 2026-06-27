import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';
import 'mock_ai_news.dart';

/// 基于本地模拟数据的 AI 资讯仓库。
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
}
