import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/features/monitor/application/monitor_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('should persist notification switches', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    await container.read(monitorSettingsControllerProvider.notifier).setEnabled(1, true);

    expect(container.read(monitorSettingsControllerProvider)[1], isTrue);

    final restored = await _container();
    addTearDown(restored.dispose);
    expect(restored.read(monitorSettingsControllerProvider)[1], isTrue);
  });
}

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}
