import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/i18n/app_localizations.dart';

const int monitorNotificationCount = 7;

List<String> monitorNotificationLabels(AppLocalizations l10n) => [
  l10n.tr('monitor.notify.app'),
  l10n.tr('monitor.notify.email'),
  l10n.tr('monitor.notify.daily'),
  l10n.tr('monitor.notify.weekly'),
  l10n.tr('monitor.notify.critical_only'),
  l10n.tr('monitor.notify.night_silent'),
  l10n.tr('monitor.notify.work_hours'),
];

class MonitorSettingsController extends Notifier<List<bool>> {
  static const _key = 'monitor_notification_settings';

  @override
  List<bool> build() {
    final raw = ref.read(sharedPreferencesProvider).getStringList(_key);
    if (raw == null || raw.length != monitorNotificationCount) {
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
