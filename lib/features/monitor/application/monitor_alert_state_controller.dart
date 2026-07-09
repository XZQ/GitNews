import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities.dart';

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
