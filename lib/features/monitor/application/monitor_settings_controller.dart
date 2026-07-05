import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

const List<String> monitorNotificationLabels = [
  '应用内通知',
  '邮件摘要',
  '每日报告',
  '周报推送',
  '仅关键告警',
  '夜间 22:00 - 08:00 静默',
  '工作时段仅推送关键',
];

class MonitorSettingsController extends Notifier<List<bool>> {
  static const _key = 'monitor_notification_settings';

  @override
  List<bool> build() {
    final raw = ref.read(sharedPreferencesProvider).getStringList(_key);
    if (raw == null || raw.length != monitorNotificationLabels.length) {
      return const [true, false, true, false, true, true, false];
    }
    return [for (final value in raw) value == '1' || value == 'true'];
  }

  Future<void> setEnabled(int index, bool enabled) async {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..[index] = enabled;
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(
      _key,
      [for (final value in next) value ? '1' : '0'],
    );
  }
}

final monitorSettingsControllerProvider =
    NotifierProvider<MonitorSettingsController, List<bool>>(
  MonitorSettingsController.new,
);
