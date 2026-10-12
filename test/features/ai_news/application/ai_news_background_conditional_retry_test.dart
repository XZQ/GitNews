import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_background_refresh.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_api_client.dart';
import 'package:github_news/features/ai_news/data/ai_news_reminder_dao.dart';
import 'package:github_news/features/ai_news/data/remote_ai_hot_repository.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
*仅替换 HTTP 出口，保留真实指纹缓存、DTO 和仓库转换。
*/
class _MockDio extends Mock implements Dio {}

/*
*控制条目下载首次失败，之后返回同一批真实样式条目。
*/
class _NewsRepository implements AiNewsRepository {
  _NewsRepository(this.item);

  // 本轮需要生成提醒的条目。
  final AiNewsItem item;

  // 条目下载可恢复的失败开关。
  bool fail = false;

  // 验证 304 后实际重试了条目下载。
  int calls = 0;

  @override
  /* 模拟一次下载结果，记录刷新是否继续经过指纹检查。 */
  Future<DataResult<AiNewsDigest>> fetchItems({AiNewsCategory? category, DateTime? since, String? query, String? cursor, bool selectedOnly = true, bool force = false}) async {
    calls++;
    if (fail) {
      throw StateError('simulated offline');
    }
    return DataResult(
      data: AiNewsDigest(items: [item], count: 1, hasNext: false),
      freshness: DataFreshness.live,
      validatedAt: item.publishedAt,
    );
  }
}

/*
*模拟提醒写入失败，恢复后仍通过真实 SQLite 幂等落库。
*/
class _ReminderDao extends AiNewsReminderDao {
  _ReminderDao(super.db);

  // 提醒持久化可恢复的失败开关。
  bool fail = false;

  @override
  /* 失败不写提醒，恢复后执行正常持久化。 */
  Future<void> addItems(List<AiNewsItem> items, {required DateTime now, String? languageCode}) async {
    if (fail) {
      throw StateError('simulated reminder failure');
    }
    await super.addItems(items, now: now, languageCode: languageCode);
  }
}

/* 使用真实条件缓存验证下载或提醒失败后的 304 重试。 */
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(Options()));

  for (final failDownload in [true, false]) {
    test('conditional fingerprint retries after ${failDownload ? 'download' : 'reminder persistence'} failure', () async {
      final now = DateTime.utc(2026, 10, 12, 12);
      final db = await LocalDatabase.openInMemory();
      addTearDown(db.close);
      SharedPreferences.setMockInitialValues({
        'ai_hot_selected_fingerprint_v1': 'old',
        'ai_news_background_seen_v1': ['known'],
      });
      final prefs = await SharedPreferences.getInstance();
      final dio = _MockDio();
      var requests = 0;
      final validators = <String?>[];
      when(
        () => dio.get<Object?>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        requests++;
        final options = invocation.namedArguments[#options] as Options;
        validators.add(options.headers?['If-None-Match'] as String?);
        return Response<Object?>(
          requestOptions: RequestOptions(path: ApiEndpointsConfig.aiHotFingerprintPath),
          statusCode: requests == 1 ? 200 : 304,
          headers: Headers.fromMap({
            'etag': ['"fingerprint-new"'],
          }),
          data: requests == 1 ? {'selected': 'new', 'all': 'all'} : null,
        );
      });
      final item = AiNewsItem(
        id: 'new-item',
        category: AiNewsCategory.industry,
        title: 'New item',
        titleEn: '',
        summary: '',
        source: 'Source',
        url: '',
        permalink: '',
        publishedAt: now,
        score: 0,
        selected: true,
      );
      final news = _NewsRepository(item)..fail = failDownload;
      final reminders = _ReminderDao(db.executor)..fail = !failDownload;
      final cache = JsonSnapshotCacheDao(db.executor, CacheMetaDao(db.executor));
      final hot = RemoteAiHotRepository(AiNewsApiClient.create(dio: dio, cache: cache, now: () => now));
      var notices = 0;
      final container = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          aiHotRepositoryProvider.overrideWithValue(hot),
          aiNewsRepositoryProvider.overrideWithValue(news),
          aiNewsReminderDaoProvider.overrideWithValue(reminders),
          aiNewsBackgroundNotificationProvider.overrideWithValue(({required title, required body}) async {
            notices++;
          }),
        ],
      );
      addTearDown(container.dispose);
      final refresher = container.read(aiNewsBackgroundRefresherProvider);
      await refresher.refresh();
      expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'old');
      expect(await reminders.readAll(), isEmpty);

      news.fail = false;
      reminders.fail = false;
      await refresher.refresh();
      expect(validators, [null, '"fingerprint-new"']);
      expect(news.calls, 2);
      expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'new');
      expect((await reminders.readAll()).single.itemId, 'new-item');
      expect(notices, 1);

      await refresher.refresh();
      expect(news.calls, 2);
      expect(await reminders.readAll(), hasLength(1));
      expect(notices, 1);
    });
  }
}
