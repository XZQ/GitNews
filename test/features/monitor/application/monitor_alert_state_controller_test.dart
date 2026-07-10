import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/monitor/application/monitor_alert_state_controller.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_rule.dart';

void main() {
  late LocalDatabase database;

  setUp(() async {
    database = await LocalDatabase.openInMemory();
  });

  tearDown(() => database.close());

  test('durable controller persists read and archived event state', () async {
    final container = _container(database);
    addTearDown(container.dispose);
    await container.read(monitorAlertEventsProvider.future);
    final controller = container.read(monitorAlertEventsProvider.notifier);

    await controller.upsertAll([event(id: 'one')]);
    await controller.markRead('one');
    await controller.archive('one');

    final current = container.read(monitorAlertEventsProvider).requireValue.single;
    expect(current.isRead, isTrue);
    expect(current.isArchived, isTrue);

    final restored = _container(database);
    addTearDown(restored.dispose);
    final persisted = (await restored.read(monitorAlertEventsProvider.future)).single;
    expect(persisted.isRead, isTrue);
    expect(persisted.isArchived, isTrue);
  });

  test('archiveRead archives only read events and restoreAll reverses it', () async {
    final container = _container(database);
    addTearDown(container.dispose);
    await container.read(monitorAlertEventsProvider.future);
    final controller = container.read(monitorAlertEventsProvider.notifier);
    await controller.upsertAll([event(id: 'read'), event(id: 'unread')]);
    await controller.markRead('read');

    await controller.archiveRead();

    final archived = container.read(monitorAlertEventsProvider).requireValue;
    expect(archived.firstWhere((item) => item.id == 'read').isArchived, isTrue);
    expect(
      archived.firstWhere((item) => item.id == 'unread').isArchived,
      isFalse,
    );

    await controller.restoreAll();
    expect(
      container.read(monitorAlertEventsProvider).requireValue.any((item) => item.isArchived),
      isFalse,
    );
  });

  test('toggleRead switches the durable read timestamp', () async {
    final container = _container(database);
    addTearDown(container.dispose);
    await container.read(monitorAlertEventsProvider.future);
    final controller = container.read(monitorAlertEventsProvider.notifier);
    await controller.upsertAll([event(id: 'one')]);

    await controller.toggleRead('one');
    expect(
      container.read(monitorAlertEventsProvider).requireValue.single.isRead,
      isTrue,
    );

    await controller.toggleRead('one');
    expect(
      container.read(monitorAlertEventsProvider).requireValue.single.isRead,
      isFalse,
    );
  });
}

ProviderContainer _container(LocalDatabase database) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      monitorAlertClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 7, 3, 12),
      ),
    ],
  );
}

MonitorAlertEvent event({required String id}) {
  return MonitorAlertEvent(
    id: id,
    repoFullName: 'owner/repo',
    ruleId: MonitorRuleIds.starDailyDelta,
    metric: 'stars',
    value: 200,
    threshold: 200,
    severity: AlertSeverity.success,
    observedAt: DateTime.utc(2026, 7, 2),
  );
}
