import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/features/monitor/application/monitor_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('keeps only the supported in-app alert-center switch', () async {
    SharedPreferences.setMockInitialValues({
      'monitor_notification_settings': ['0', '1', '1', '1', '1', '1', '1']
    });
    final container = await _container();
    addTearDown(container.dispose);

    expect(monitorNotificationCount, 1);
    expect(container.read(monitorSettingsControllerProvider), [false]);

    await container.read(monitorSettingsControllerProvider.notifier).setEnabled(0, true);

    expect(container.read(monitorSettingsControllerProvider), [true]);

    final restored = await _container();
    addTearDown(restored.dispose);
    expect(restored.read(monitorSettingsControllerProvider), [true]);
  });
}

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}
