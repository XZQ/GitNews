import '../../../core/domain/data_freshness.dart';
import '../domain/ai_hot_daily.dart';
import '../domain/ai_hot_repository.dart';
import '../domain/ai_hot_status.dart';
import '../domain/ai_hot_topic.dart';
import 'ai_news_api_client.dart';

/*
*AI HOT 热点、日报与状态端点的远程仓库实现。
*/
class RemoteAiHotRepository implements AiHotRepository {
  const RemoteAiHotRepository(this._client);

  // 带条件缓存的 AI HOT REST 客户端。
  final AiNewsApiClient _client;

  @override
  Future<DataResult<List<AiHotTopic>>> fetchHotTopics({bool force = false}) => _client.fetchHotTopics(force: force);

  @override
  Future<DataResult<AiHotDailyReport>> fetchLatestDaily({bool force = false}) => _client.fetchLatestDaily(force: force);

  @override
  Future<DataResult<AiHotDailyReport>> fetchDaily(String date, {bool force = false}) => _client.fetchDaily(date, force: force);

  @override
  Future<DataResult<List<AiHotDailyEntry>>> fetchDailies({int take = 30, bool force = false}) => _client.fetchDailies(take: take, force: force);

  @override
  Future<DataResult<AiHotFingerprint>> fetchFingerprint({bool force = false}) => _client.fetchFingerprint(force: force);

  @override
  Future<DataResult<AiHotVersion>> fetchVersion({bool force = false}) => _client.fetchVersion(force: force);
}
