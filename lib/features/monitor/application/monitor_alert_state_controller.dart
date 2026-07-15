import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/monitor_alert_event_dao.dart';
import '../domain/monitor_rule.dart';

enum MonitorAlertFilter { all, unread, important }

final monitorAlertFilterProvider = StateProvider<MonitorAlertFilter>((ref) => MonitorAlertFilter.all);

final monitorAlertEventDaoProvider = Provider<MonitorAlertEventDao>((ref) {
  return MonitorAlertEventDao(ref.watch(appDatabaseProvider).executor);
});

final monitorAlertClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class MonitorAlertEventsController extends AsyncNotifier<List<MonitorAlertEvent>> {
  MonitorAlertEventDao get _dao => ref.read(monitorAlertEventDaoProvider);

  DateTime get _now => ref.read(monitorAlertClockProvider)();

  @override
  Future<List<MonitorAlertEvent>> build() {
    return _dao.list(includeArchived: true);
  }

  Future<void> upsertAll(Iterable<MonitorAlertEvent> events) async {
    await _dao.upsertAll(events);
    await _reload();
  }

  Future<void> markRead(String id) async {
    await _dao.markRead(id, _now);
    await _reload();
  }

  Future<void> toggleRead(String id) async {
    final events = state.valueOrNull ?? await _dao.list(includeArchived: true);
    final event = events.where((item) => item.id == id).firstOrNull;
    if (event == null) {
      return;
    }
    if (event.isRead) {
      await _dao.markUnread(id);
    } else {
      await _dao.markRead(id, _now);
    }
    await _reload();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    await _dao.markAllRead(ids, _now);
    await _reload();
  }

  Future<void> archive(String id) async {
    await _dao.archive(id, _now);
    await _reload();
  }

  Future<void> archiveRead() async {
    await _dao.archiveRead(_now);
    await _reload();
  }

  Future<void> restoreAll() async {
    await _dao.restoreAll();
    await _reload();
  }

  Future<void> _reload() async {
    state = AsyncData(await _dao.list(includeArchived: true));
  }
}

final monitorAlertEventsProvider = AsyncNotifierProvider<MonitorAlertEventsController, List<MonitorAlertEvent>>(MonitorAlertEventsController.new);
