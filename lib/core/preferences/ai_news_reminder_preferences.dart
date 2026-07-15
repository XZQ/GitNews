import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

const String aiNewsRemindersEnabledPreferenceKey = 'ai_news_reminders_enabled';

class AiNewsReminderPreferences extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(aiNewsRemindersEnabledPreferenceKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(aiNewsRemindersEnabledPreferenceKey, enabled);
  }
}

final aiNewsReminderPreferencesProvider = NotifierProvider<AiNewsReminderPreferences, bool>(
  AiNewsReminderPreferences.new,
);
