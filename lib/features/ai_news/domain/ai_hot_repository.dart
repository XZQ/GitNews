import '../../../core/domain/data_freshness.dart';
import 'ai_hot_daily.dart';
import 'ai_hot_status.dart';
import 'ai_hot_topic.dart';

/*
*AI HOT 公开辅助端点仓库。
*items 时间线继续由 [AiNewsRepository] 负责,热点、日报与轮询状态在此隔离。
*/
abstract interface class AiHotRepository {
  /* 读取当前多信源热点。 */
  Future<DataResult<List<AiHotTopic>>> fetchHotTopics({bool force = false});

  /* 读取最新官方日报。 */
  Future<DataResult<AiHotDailyReport>> fetchLatestDaily({bool force = false});

  /* 读取指定 YYYY-MM-DD 日报。 */
  Future<DataResult<AiHotDailyReport>> fetchDaily(String date, {bool force = false});

  /* 读取最近日报日期索引。 */
  Future<DataResult<List<AiHotDailyEntry>>> fetchDailies({int take = 30, bool force = false});

  /* 读取轻量内容指纹。 */
  Future<DataResult<AiHotFingerprint>> fetchFingerprint({bool force = false});

  /* 读取 API/Skill 版本信息。 */
  Future<DataResult<AiHotVersion>> fetchVersion({bool force = false});
}
