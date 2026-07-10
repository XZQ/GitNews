import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/monitor_alert_event_dao.dart';
import '../domain/entities.dart';
import '../domain/monitor_rule.dart';

enum MonitorAlertFilter { all, unread, important }

class MonitorAlertState {
  const MonitorAlertState({
    required this.readAlertIds,
    required this.archivedAlertIds,
  });

  final Set<String> readAlertIds;
  final Set<String> archivedAlertIds;

  bool isRead(AlertEntity alert) => readAlertIds.contains(alertStableId(alert));

  bool isArchived(AlertEntity alert) => archivedAlertIds.contains(alertStableId(alert));

  List<AlertEntity> visibleAlerts(Iterable<AlertEntity> alerts) {
    return [
      for (final alert in alerts)
        if (!isArchived(alert)) alert,
    ];
  }

  int unreadCount(Iterable<AlertEntity> alerts) {
    return visibleAlerts(alerts).where((alert) => !isRead(alert)).length;
  }

  MonitorAlertState copyWith({
    Set<String>? readAlertIds,
    Set<String>? archivedAlertIds,
  }) {
    return MonitorAlertState(
      readAlertIds: readAlertIds ?? this.readAlertIds,
      archivedAlertIds: archivedAlertIds ?? this.archivedAlertIds,
    );
  }
}

class MonitorAlertStateController extends Notifier<MonitorAlertState> {
  static const _readKey = 'monitor_alert_read_ids';
  static const _archivedKey = 'monitor_alert_archived_ids';

  @override
  MonitorAlertState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return MonitorAlertState(
      readAlertIds: _readSet(prefs.getStringList(_readKey)),
      archivedAlertIds: _readSet(prefs.getStringList(_archivedKey)),
    );
  }

  Future<void> toggleRead(AlertEntity alert) async {
    final id = alertStableId(alert);
    final next = {...state.readAlertIds};
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(readAlertIds: next);
    await _persistSet(_readKey, next);
  }

  Future<void> markRead(AlertEntity alert) async {
    final id = alertStableId(alert);
    if (state.readAlertIds.contains(id)) {
      return;
    }
    final next = {...state.readAlertIds, id};
    state = state.copyWith(readAlertIds: next);
    await _persistSet(_readKey, next);
  }

  Future<void> markAllRead(Iterable<AlertEntity> alerts) async {
    final next = {
      ...state.readAlertIds,
      for (final alert in alerts) alertStableId(alert),
    };
    state = state.copyWith(readAlertIds: next);
    await _persistSet(_readKey, next);
  }

  Future<void> archive(AlertEntity alert) async {
    final id = alertStableId(alert);
    final archived = {...state.archivedAlertIds, id};
    final read = {...state.readAlertIds, id};
    state = state.copyWith(readAlertIds: read, archivedAlertIds: archived);
    await Future.wait([
      _persistSet(_readKey, read),
      _persistSet(_archivedKey, archived),
    ]);
  }

  Future<void> archiveRead(Iterable<AlertEntity> alerts) async {
    final readIds = state.readAlertIds;
    final archived = {
      ...state.archivedAlertIds,
      for (final alert in alerts)
        if (readIds.contains(alertStableId(alert))) alertStableId(alert),
    };
    state = state.copyWith(archivedAlertIds: archived);
    await _persistSet(_archivedKey, archived);
  }

  Future<void> restoreAll() async {
    if (state.archivedAlertIds.isEmpty) {
      return;
    }
    state = state.copyWith(archivedAlertIds: <String>{});
    await _persistSet(_archivedKey, const <String>{});
  }

  Set<String> _readSet(List<String>? raw) {
    return (raw ?? const <String>[]).where((item) => item.trim().isNotEmpty).toSet();
  }

  Future<void> _persistSet(String key, Set<String> values) {
    final sorted = values.toList()..sort();
    return ref.read(sharedPreferencesProvider).setStringList(key, sorted);
  }
}

final monitorAlertStateControllerProvider = NotifierProvider<MonitorAlertStateController, MonitorAlertState>(
  MonitorAlertStateController.new,
);

final monitorAlertFilterProvider = StateProvider<MonitorAlertFilter>(
  (ref) => MonitorAlertFilter.all,
);

String alertStableId(AlertEntity alert) {
  return [
    alert.repoFullName,
    alert.metric,
    alert.value,
    alert.time,
    alert.severity.name,
  ].map(Uri.encodeComponent).join('|');
}

final monitorAlertEventDaoProvider = Provider<MonitorAlertEventDao>((ref) {
  return MonitorAlertEventDao(ref.watch(appDatabaseProvider).executor);
});

final monitorAlertClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

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

final monitorAlertEventsProvider = AsyncNotifierProvider<MonitorAlertEventsController, List<MonitorAlertEvent>>(
  MonitorAlertEventsController.new,
);
