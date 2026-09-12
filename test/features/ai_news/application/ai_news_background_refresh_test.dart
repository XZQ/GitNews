import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_background_refresh.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/data/ai_news_reminder_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_hot_repository.dart';
import 'package:github_news/features/ai_news/domain/ai_hot_status.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HotRepository extends Mock implements AiHotRepository {}

class _NewsRepository extends Mock implements AiNewsRepository {}

/*
*只注入提醒写入失败，其余操作使用真实内存 SQLite。
*/
class _ReminderDao extends AiNewsReminderDao {
  _ReminderDao(super.db);

  // 模拟写入失败后恢复。
  bool fail = false;

  @override
  Future<void> addItems(List<AiNewsItem> items, {required DateTime now, String? languageCode}) async {
    if (fail) {
      throw StateError('simulated reminder write failure');
    }
    await super.addItems(items, now: now, languageCode: languageCode);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 12, 12);
  late LocalDatabase db;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late _HotRepository hot;
  late _NewsRepository news;
  late _ReminderDao reminders;
  late AiNewsBackgroundRefresher refresher;
  late DataResult<AiHotFingerprint> fingerprint;
  late DataResult<AiNewsDigest> response;
  var notices = 0;

  setUp(() async {
    db = await LocalDatabase.openInMemory();
    SharedPreferences.setMockInitialValues({
      'ai_hot_selected_fingerprint_v1': 'old',
      'ai_news_background_seen_v1': ['known'],
    });
    prefs = await SharedPreferences.getInstance();
    hot = _HotRepository();
    news = _NewsRepository();
    reminders = _ReminderDao(db.executor);
    notices = 0;
    fingerprint = const DataResult(
      data: AiHotFingerprint(selected: 'new', all: 'all'),
      freshness: DataFreshness.live,
    );
    response = DataResult(
      data: AiNewsDigest(items: [_item('new-item', now)], count: 1, hasNext: false),
      freshness: DataFreshness.live,
      validatedAt: now,
    );
    when(() => hot.fetchFingerprint(force: true)).thenAnswer((_) async => fingerprint);
    when(() => news.fetchItems(selectedOnly: true, force: true)).thenAnswer((_) async => response);
    container = ProviderContainer.test(
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
    refresher = container.read(aiNewsBackgroundRefresherProvider);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('failed items download retries the same fingerprint and commits only after success', () async {
    when(() => news.fetchItems(selectedOnly: true, force: true)).thenThrow(StateError('simulated offline'));
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'old');
    expect(prefs.getStringList('ai_news_background_seen_v1'), ['known']);
    when(() => news.fetchItems(selectedOnly: true, force: true)).thenAnswer((_) async => response);
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'new');
    expect((await reminders.readAll()).single.itemId, 'new-item');
    expect(notices, 1);
    await refresher.refresh();
    verify(() => news.fetchItems(selectedOnly: true, force: true)).called(2);
    expect(notices, 1);
  });

  test('failed reminder write preserves both checkpoints and retries without duplicate rows', () async {
    reminders.fail = true;
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'old');
    expect(prefs.getStringList('ai_news_background_seen_v1'), ['known']);
    reminders.fail = false;
    await refresher.refresh();
    expect(await reminders.readAll(), hasLength(1));
    expect(prefs.getStringList('ai_news_background_seen_v1'), ['new-item', 'known']);
    await prefs.setString('ai_hot_selected_fingerprint_v1', 'old');
    await prefs.setStringList('ai_news_background_seen_v1', ['known']);
    await refresher.refresh();
    expect(await reminders.readAll(), hasLength(1));
  });

  test('first empty success establishes a baseline for later new items', () async {
    await prefs.remove('ai_news_background_seen_v1');
    response = const DataResult(
      data: AiNewsDigest(items: [], count: 0, hasNext: false),
      freshness: DataFreshness.live,
    );
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'new');
    expect(prefs.getStringList('ai_news_background_seen_v1'), isEmpty);
    expect(notices, 0);
    fingerprint = const DataResult(
      data: AiHotFingerprint(selected: 'next', all: 'all'),
      freshness: DataFreshness.live,
    );
    response = DataResult(
      data: AiNewsDigest(items: [_item('new-item', now)], count: 1, hasNext: false),
      freshness: DataFreshness.live,
    );
    await refresher.refresh();
    expect(await reminders.readAll(), hasLength(1));
    expect(notices, 1);
  });

  test('stale fingerprint never confirms progress or triggers downloads', () async {
    fingerprint = DataResult(data: fingerprint.data, freshness: DataFreshness.staleCache);
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'old');
    verifyNever(() => news.fetchItems(selectedOnly: true, force: true));
  });

  test('stale items never advance the fingerprint or notification baseline', () async {
    response = DataResult(data: response.data, freshness: DataFreshness.staleCache);
    await refresher.refresh();
    expect(prefs.getString('ai_hot_selected_fingerprint_v1'), 'old');
    expect(prefs.getStringList('ai_news_background_seen_v1'), ['known']);
    expect(await reminders.readAll(), isEmpty);
  });

  test('overlapping lifecycle triggers share one download', () async {
    final pending = Completer<DataResult<AiNewsDigest>>();
    when(() => news.fetchItems(selectedOnly: true, force: true)).thenAnswer((_) => pending.future);
    final first = refresher.refresh();
    await refresher.refresh();
    pending.complete(response);
    await first;
    verify(() => news.fetchItems(selectedOnly: true, force: true)).called(1);
  });
}

/* 最小公开资讯，不含网络或账户信息。 */
AiNewsItem _item(String id, DateTime at) =>
    AiNewsItem(id: id, category: AiNewsCategory.industry, title: id, titleEn: '', summary: '', source: 'Source', url: '', permalink: '', publishedAt: at, score: 0, selected: true);
