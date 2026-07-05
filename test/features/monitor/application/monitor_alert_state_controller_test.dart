import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/features/monitor/application/monitor_alert_state_controller.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alert = AlertEntity(
  repoFullName: 'openai/codex',
  metric: 'Star growth',
  value: '+240',
  time: '10 min ago',
  severity: AlertSeverity.warning,
);

void main() {
  test('should persist read and archived alert state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    final controller = container.read(
      monitorAlertStateControllerProvider.notifier,
    );
    await controller.markRead(_alert);
    await controller.archive(_alert);

    expect(
      container.read(monitorAlertStateControllerProvider).isRead(_alert),
      isTrue,
    );
    expect(
      container.read(monitorAlertStateControllerProvider).isArchived(_alert),
      isTrue,
    );

    final restored = await _container();
    addTearDown(restored.dispose);

    expect(
      restored.read(monitorAlertStateControllerProvider).isRead(_alert),
      isTrue,
    );
    expect(
      restored.read(monitorAlertStateControllerProvider).isArchived(_alert),
      isTrue,
    );
  });

  test('archiveRead should archive only read alerts', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);
    const unread = AlertEntity(
      repoFullName: 'vercel/next.js',
      metric: 'Fork growth',
      value: '+52',
      time: '1 hour ago',
      severity: AlertSeverity.info,
    );

    final controller = container.read(
      monitorAlertStateControllerProvider.notifier,
    );
    await controller.markRead(_alert);
    await controller.archiveRead(const [_alert, unread]);

    final state = container.read(monitorAlertStateControllerProvider);
    expect(state.isArchived(_alert), isTrue);
    expect(state.isArchived(unread), isFalse);
  });
}

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}
