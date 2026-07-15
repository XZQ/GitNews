import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities.dart';
import '../domain/monitor_rule.dart';

const int monitorAlertEventMaxRows = 500;

class MonitorAlertEventDao {
  MonitorAlertEventDao(this._db);

  final DatabaseExecutor _db;

  static const String _table = 'monitor_alert_event';

  Future<void> upsertAll(Iterable<MonitorAlertEvent> events) {
    return _guard('monitorAlert.upsertAll', () async {
      final batch = _db.batch();
      for (final event in events) {
        batch.insert(_table, _toRow(event), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
      await _prune();
    });
  }

  Future<List<MonitorAlertEvent>> list({bool includeArchived = false}) {
    return _guard('monitorAlert.list', () async {
      final rows = await _db.query(_table, where: includeArchived ? null : 'archived_at IS NULL', orderBy: 'observed_at DESC, id DESC');
      return rows.map(_fromRow).toList(growable: false);
    });
  }

  Future<void> markRead(String id, DateTime at) {
    return _guard('monitorAlert.markRead', () async {
      await _db.update(
        _table,
        {'read_at': at.toUtc().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> markUnread(String id) {
    return _guard('monitorAlert.markUnread', () async {
      await _db.update(
        _table,
        {'read_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> markAllRead(Iterable<String> ids, DateTime at) {
    return _guard('monitorAlert.markAllRead', () async {
      final batch = _db.batch();
      for (final id in ids) {
        batch.update(
          _table,
          {'read_at': at.toUtc().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> archive(String id, DateTime at) {
    return _guard('monitorAlert.archive', () async {
      final milliseconds = at.toUtc().millisecondsSinceEpoch;
      await _db.rawUpdate(
        'UPDATE $_table '
        'SET read_at = COALESCE(read_at, ?), archived_at = ? '
        'WHERE id = ?',
        [milliseconds, milliseconds, id],
      );
    });
  }

  Future<void> archiveRead(DateTime at) {
    return _guard('monitorAlert.archiveRead', () async {
      await _db.update(_table, {'archived_at': at.toUtc().millisecondsSinceEpoch}, where: 'read_at IS NOT NULL AND archived_at IS NULL');
    });
  }

  Future<void> restoreAll() {
    return _guard('monitorAlert.restoreAll', () async {
      await _db.update(_table, {'archived_at': null}, where: 'archived_at IS NOT NULL');
    });
  }

  Future<void> _prune() async {
    final overflow = await _db.query(
      _table,
      columns: ['id'],
      orderBy: 'observed_at DESC, id DESC',
      offset: monitorAlertEventMaxRows,
    );
    if (overflow.isEmpty) {
      return;
    }
    final ids = [for (final row in overflow) row['id'] as String];
    final placeholders = List.filled(ids.length, '?').join(',');
    await _db.delete(_table, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Map<String, Object?> _toRow(MonitorAlertEvent event) {
    return {
      'id': event.id,
      'repo_full_name': event.repoFullName,
      'rule_id': event.ruleId,
      'metric': event.metric,
      'value': event.value,
      'threshold': event.threshold,
      'severity': event.severity.name,
      'observed_at': event.observedAt.toUtc().millisecondsSinceEpoch,
      'read_at': event.readAt?.toUtc().millisecondsSinceEpoch,
      'archived_at': event.archivedAt?.toUtc().millisecondsSinceEpoch
    };
  }

  MonitorAlertEvent _fromRow(Map<String, Object?> row) {
    return MonitorAlertEvent(
      id: row['id'] as String,
      repoFullName: row['repo_full_name'] as String,
      ruleId: row['rule_id'] as String,
      metric: row['metric'] as String,
      value: (row['value'] as num).toDouble(),
      threshold: (row['threshold'] as num).toDouble(),
      severity: AlertSeverity.values.firstWhere((value) => value.name == row['severity'], orElse: () => AlertSeverity.info),
      observedAt: DateTime.fromMillisecondsSinceEpoch(row['observed_at'] as int, isUtc: true),
      readAt: _date(row['read_at']),
      archivedAt: _date(row['archived_at']),
    );
  }

  DateTime? _date(Object? raw) {
    if (raw is! int) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stack) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: error,
        stack: stack,
        meta: {'op': operation},
      );
    }
  }
}
