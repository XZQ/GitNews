import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';
import 'ai_news_api_client.dart';

/* 远端实现:走 [AiNewsApiClient] 拉 aihot.virxact.com 的公开条目。 */
class RemoteAiNewsRepository implements AiNewsRepository {
  const RemoteAiNewsRepository(this._client);

  final AiNewsApiClient _client;

  @override
  Future<AiNewsDigest> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) {
    return _client
        .fetchItems(
          category: category?.code,
          since: since,
          query: query,
          cursor: cursor,
          selectedOnly: selectedOnly,
        )
        .then((r) => r.toDomain());
  }
}
