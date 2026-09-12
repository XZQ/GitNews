import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/platform/desktop_integration_service.dart';
import '../../../core/preferences/ai_news_reminder_preferences.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_library_providers.dart';
import 'ai_news_providers.dart';
import 'ai_news_reminder_providers.dart';

const String _seenPreferenceKey = 'ai_news_background_seen_v1';
const String _fingerprintPreferenceKey = 'ai_hot_selected_fingerprint_v1';

/*
*系统通知出口；测试只替换平台副作用，保留真实缓存与提醒持久化。
*/
typedef AiNewsBackgroundNotification = Future<void> Function({required String title, required String body});

final aiNewsBackgroundNotificationProvider = Provider<AiNewsBackgroundNotification>((ref) => DesktopIntegrationService.instance.showNotification);
final aiNewsBackgroundRefresherProvider = Provider<AiNewsBackgroundRefresher>(AiNewsBackgroundRefresher.new);

/*
*后台刷新事务顺序：验证指纹、保存资讯、幂等写提醒，最后确认处理位置。
*SQLite 写入和偏好检查点之间崩溃时允许重放；系统通知属于尽力投递。
*/
class AiNewsBackgroundRefresher {
  AiNewsBackgroundRefresher(this._ref);

  // 依赖容器；异步工作开始前捕获持久化与网络出口。
  final Ref _ref;

  // 合并计时器和恢复前台同时触发的刷新。
  bool _refreshing = false;

  /* 成功持久化后才推进指纹；失败留待下一轮或恢复前台重试。 */
  Future<void> refresh() async {
    if (_refreshing || !_ref.read(aiNewsReminderPreferencesProvider)) {
      return;
    }
    _refreshing = true;
    try {
      final preferences = _ref.read(sharedPreferencesProvider);
      final hotRepository = _ref.read(aiHotRepositoryProvider);
      final newsRepository = _ref.read(aiNewsRepositoryProvider);
      final cache = _ref.read(aiNewsCacheDaoProvider);
      final reminders = _ref.read(aiNewsReminderDaoProvider);
      final notify = _ref.read(aiNewsBackgroundNotificationProvider);
      final clock = _ref.read(clockProvider);
      final fingerprint = await hotRepository.fetchFingerprint(force: true);
      if (!_successfullyChecked(fingerprint)) {
        return;
      }
      final selected = fingerprint.data.selected;
      if (!shouldFetchAiHotItems(previousFingerprint: preferences.getString(_fingerprintPreferenceKey), currentFingerprint: selected)) {
        return;
      }
      // 指纹变化时必须穿过 items 的 TTL，不能用旧 head 确认新指纹。
      final result = await newsRepository.fetchItems(selectedOnly: true, force: true);
      final now = clock().toUtc();
      final items = result.data.items;
      if (result.freshness == DataFreshness.seed) return;
      final validatedAt = result.validatedAt ?? (result.freshness == DataFreshness.live ? now : null);
      await cache.upsertPage(
        category: null,
        cursor: null,
        digest: result.data,
        now: validatedAt ?? await cache.lastValidatedAt() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        validated: validatedAt != null && _successfullyChecked(result),
      );
      if (!_successfullyChecked(result)) {
        return;
      }
      final previous = preferences.getStringList(_seenPreferenceKey) ?? const <String>[];
      final freshItems = detectNewAiNewsItems(items, seenIds: previous.toSet(), now: now, hasBaseline: preferences.containsKey(_seenPreferenceKey));
      final savedLanguage = preferences.getString('app_locale')?.split(RegExp('[_-]')).first;
      final language = (savedLanguage ?? PlatformDispatcher.instance.locale.languageCode).toLowerCase() == 'zh' ? 'zh' : 'en';
      if (freshItems.isNotEmpty) {
        await reminders.addItems(freshItems, now: now, languageCode: language);
      }
      // seen 和指纹都在幂等提醒写入之后更新。任何失败都不跳过未落库提醒。
      if (!await preferences.setStringList(_seenPreferenceKey, <String>{...items.map((item) => item.id), ...previous}.take(300).toList())) {
        return;
      }
      if (!await preferences.setString(_fingerprintPreferenceKey, selected)) {
        return;
      }
      if (!_ref.mounted) {
        return;
      }
      _ref
        ..invalidate(aiNewsRemindersProvider)
        ..invalidate(aiNewsItemsNotifierProvider)
        ..invalidate(aiNewsLibrarySourcesProvider);
      if (freshItems.isNotEmpty) {
        await notify(
          title: language == 'zh' ? 'AI 资讯更新' : 'New AI updates',
          body: _notificationBody(freshItems, languageCode: language),
        );
      }
    } catch (_) {
      // 失败不推进尚未完成的检查点；下一轮仍可重放，前台继续读取原缓存。
    } finally {
      _refreshing = false;
    }
  }
}

/* 成功远端响应或经过本次条件验证的缓存才可确认处理位置。 */
bool _successfullyChecked(DataResult<Object> result) => result.freshness == DataFreshness.live || (result.freshness == DataFreshness.freshCache && result.revalidated);

/* 判断本次指纹探测是否需要继续拉取 items。 */
bool shouldFetchAiHotItems({required String? previousFingerprint, required String currentFingerprint}) => currentFingerprint.isNotEmpty && previousFingerprint != currentFingerprint;

/* 首次建立基线不提醒；已验证的空列表也属于基线。 */
List<AiNewsItem> detectNewAiNewsItems(List<AiNewsItem> items, {required Set<String> seenIds, required DateTime now, bool? hasBaseline}) {
  if (!(hasBaseline ?? seenIds.isNotEmpty)) {
    return const [];
  }
  final oldest = now.subtract(const Duration(days: 2));
  return [
    for (final item in items)
      if (!seenIds.contains(item.id) && !item.publishedAt.isBefore(oldest)) item,
  ];
}

/* 按应用语言生成紧凑的系统通知摘要。 */
String _notificationBody(List<AiNewsItem> items, {required String languageCode}) {
  final first = items.first.titleForLanguage(languageCode);
  return items.length == 1
      ? first
      : languageCode == 'zh'
      ? '$first 等 ${items.length} 条'
      : '$first and ${items.length - 1} more';
}
