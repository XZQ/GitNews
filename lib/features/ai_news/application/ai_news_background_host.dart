import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/platform/desktop_integration_service.dart';
import '../../../core/preferences/ai_news_reminder_preferences.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_library_providers.dart';
import 'ai_news_providers.dart';
import 'ai_news_reminder_providers.dart';

const Duration aiNewsBackgroundRefreshInterval = Duration(minutes: 15);
const String _seenPreferenceKey = 'ai_news_background_seen_v1';

/*
*托盘常驻期间的前台进程轮询宿主。首次运行只建立基线，后续刷新发现
*新条目时写入应用内提醒，并尽力发送桌面系统通知。
*/
class AiNewsBackgroundHost extends ConsumerStatefulWidget {
  const AiNewsBackgroundHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AiNewsBackgroundHost> createState() => _AiNewsBackgroundHostState();
}

class _AiNewsBackgroundHostState extends ConsumerState<AiNewsBackgroundHost> with WidgetsBindingObserver {
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (DesktopIntegrationService.instance.active) {
      unawaited(_refresh());
      _timer = Timer.periodic(
        aiNewsBackgroundRefreshInterval,
        (_) => _refresh(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _refresh() async {
    if (_refreshing || !ref.read(aiNewsReminderPreferencesProvider)) {
      return;
    }
    _refreshing = true;
    try {
      final now = ref.read(clockProvider)().toUtc();
      final result = await ref.read(aiNewsRepositoryProvider).fetchItems();
      final items = result.data.items;
      if (items.isEmpty) {
        return;
      }
      await ref.read(aiNewsCacheDaoProvider).upsertPage(
            category: null,
            cursor: null,
            digest: result.data,
            now: now,
          );
      final preferences = ref.read(sharedPreferencesProvider);
      final previous = preferences.getStringList(_seenPreferenceKey) ?? const [];
      final freshItems = detectNewAiNewsItems(
        items,
        seenIds: previous.toSet(),
        now: now,
      );
      // 与历史合并而非整表覆盖:head 页只有几十条,单源临时失败会把
      // 老条目挤出列表;若直接覆盖,源恢复后这些条目会被误判为新条目
      // 而重复提醒。新 id 在前,截断只淘汰最旧的。
      await preferences.setStringList(
        _seenPreferenceKey,
        <String>{...items.map((item) => item.id), ...previous}.take(300).toList(),
      );
      if (previous.isEmpty || freshItems.isEmpty) {
        return;
      }
      await ref.read(aiNewsReminderDaoProvider).addItems(freshItems, now: now);
      ref
        ..invalidate(aiNewsRemindersProvider)
        ..invalidate(aiNewsItemsNotifierProvider)
        ..invalidate(aiNewsLibrarySourcesProvider);
      final locale = preferences.getString('app_locale') ?? 'zh_CN';
      await DesktopIntegrationService.instance.showNotification(
        title: locale == 'en_US' ? 'New AI updates' : 'AI 资讯更新',
        body: _notificationBody(freshItems, english: locale == 'en_US'),
      );
    } catch (_) {
      // 后台刷新是增强能力；网络或通知失败不改变前台数据的降级链。
    } finally {
      _refreshing = false;
    }
  }
}

List<AiNewsItem> detectNewAiNewsItems(
  List<AiNewsItem> items, {
  required Set<String> seenIds,
  required DateTime now,
}) {
  if (seenIds.isEmpty) {
    return const [];
  }
  final oldest = now.subtract(const Duration(days: 2));
  return [
    for (final item in items)
      if (!seenIds.contains(item.id) && !item.publishedAt.isBefore(oldest)) item,
  ];
}

String _notificationBody(List<AiNewsItem> items, {required bool english}) {
  final first = items.first.title.isEmpty ? items.first.titleEn : items.first.title;
  if (items.length == 1) {
    return first;
  }
  return english ? '$first and ${items.length - 1} more' : '$first 等 ${items.length} 条';
}
