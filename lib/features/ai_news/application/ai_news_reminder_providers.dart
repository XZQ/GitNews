import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/ai_news_reminder_dao.dart';
import '../domain/ai_news_reminder.dart';
import 'ai_news_providers.dart';

final aiNewsReminderDaoProvider = Provider<AiNewsReminderDao>(
  (ref) => AiNewsReminderDao(ref.watch(appDatabaseProvider).executor),
);

final aiNewsRemindersProvider = FutureProvider<List<AiNewsReminder>>(
  (ref) => ref.watch(aiNewsReminderDaoProvider).readAll(),
);

final aiNewsUnreadReminderCountProvider = Provider<int>((ref) {
  final reminders = ref.watch(aiNewsRemindersProvider).valueOrNull ?? const [];
  return reminders.where((reminder) => !reminder.isRead).length;
});

final aiNewsReminderControllerProvider = Provider<AiNewsReminderController>(
  AiNewsReminderController.new,
);

class AiNewsReminderController {
  const AiNewsReminderController(this._ref);

  final Ref _ref;

  Future<void> markRead(String itemId) async {
    await _ref.read(aiNewsReminderDaoProvider).markRead(itemId, now: _ref.read(clockProvider)().toUtc());
    _ref.invalidate(aiNewsRemindersProvider);
  }

  Future<void> markAllRead() async {
    await _ref.read(aiNewsReminderDaoProvider).markAllRead(now: _ref.read(clockProvider)().toUtc());
    _ref.invalidate(aiNewsRemindersProvider);
  }
}
