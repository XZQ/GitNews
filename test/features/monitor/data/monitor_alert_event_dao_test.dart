import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/monitor/data/monitor_alert_event_dao.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_rule.dart';

void main() {
  late LocalDatabase database;
  late MonitorAlertEventDao dao;

  setUp(() async {
    database = await LocalDatabase.openInMemory();
    dao = MonitorAlertEventDao(database.executor);
  });

  tearDown(() => database.close());

  test('upsert is idempotent and list is newest first', () async {
    await dao.upsertAll([event(id: 'one', minute: 1)]);
    await dao.upsertAll([event(id: 'one', minute: 1)]);
    await dao.upsertAll([event(id: 'two', minute: 2)]);

    final events = await dao.list();

    expect(events.map((item) => item.id), ['two', 'one']);
  });

  test('read archive and restore timestamps persist', () async {
    await dao.upsertAll([event(id: 'one')]);
    final readAt = DateTime.utc(
      2026,
      7,
      3,
      10,
    );
    final archivedAt = DateTime.utc(
      2026,
      7,
      3,
      11,
    );

    await dao.markRead('one', readAt);
    await dao.archive('one', archivedAt);

    expect(await dao.list(), isEmpty);
    final archived = (await dao.list(includeArchived: true)).single;
    expect(archived.readAt, readAt);
    expect(archived.archivedAt, archivedAt);

    await dao.restoreAll();
    expect((await dao.list()).single.archivedAt, isNull);
  });

  test('markUnread clears only the read timestamp', () async {
    await dao.upsertAll([event(id: 'one')]);
    await dao.markRead(
        'one',
        DateTime.utc(
          2026,
          7,
          3,
          10,
        ));

    await dao.markUnread('one');

    expect((await dao.list()).single.readAt, isNull);
  });

  test('archiveRead archives only read events', () async {
    await dao.upsertAll([event(id: 'read'), event(id: 'unread', minute: 2)]);
    final now = DateTime.utc(
      2026,
      7,
      3,
      12,
    );
    await dao.markRead('read', now);

    await dao.archiveRead(now);

    expect((await dao.list()).single.id, 'unread');
  });

  test('pruning keeps the newest 500 events', () async {
    await dao.upsertAll([for (var i = 0; i < 505; i++) event(id: 'event-$i', minute: i)]);

    final events = await dao.list(includeArchived: true);

    expect(events, hasLength(500));
    expect(events.first.id, 'event-504');
    expect(events.last.id, 'event-5');
  });

  test('cache clear preserves durable alert events', () async {
    await dao.upsertAll([event(id: 'one')]);

    await database.clearAll();

    expect(await dao.list(includeArchived: true), hasLength(1));
  });
}

MonitorAlertEvent event({required String id, int minute = 0}) {
  return MonitorAlertEvent(
    id: id,
    repoFullName: 'owner/repo',
    ruleId: MonitorRuleIds.starDailyDelta,
    metric: 'stars',
    value: 200,
    threshold: 200,
    severity: AlertSeverity.success,
    observedAt: DateTime.utc(2026, 7, 2).add(Duration(minutes: minute)),
  );
}
