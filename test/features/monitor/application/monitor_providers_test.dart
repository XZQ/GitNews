import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/monitor/application/monitor_alert_state_controller.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/data/local_monitor_repository.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:github_news/features/monitor/domain/monitor_rule.dart';
import 'package:github_news/features/monitor/widgets/monitor_alert_list_tile.dart';
import 'package:mocktail/mocktail.dart';

class _MockMonitorRepository extends Mock implements MonitorRepository {}

class _FakeMonitorAlertEventsController extends MonitorAlertEventsController {
  _FakeMonitorAlertEventsController(this.events);

  final List<MonitorAlertEvent> events;

  @override
  Future<List<MonitorAlertEvent>> build() async => events;
}

RepoEntity _repo(
  String fullName, {
  String description = 'AI coding project',
  String language = 'Dart',
}) {
  return RepoEntity(
    fullName: fullName,
    description: description,
    language: language,
    starCount: 1200,
    starDelta: 80,
    forkCount: 30,
    accentArgb: 0xFF00A389,
  );
}

const _stats = MonitorStats(
  monitoredCount: 2,
  monitoredDelta: 1,
  unreadAlertCount: 1,
  unreadAlertDelta: 1,
  triggeredTodayCount: 1,
  triggeredTodayDelta: 0,
  totalAlertCount: 3,
  totalAlertDelta: 1,
);

void main() {
  group('monitor repository selection', () {
    test('explicit empty monitor selection stays empty', () {
      expect(monitorReposFor(<String>{}), isEmpty);
    });

    test('selected repositories use deterministic ordering', () {
      expect(
        monitorReposFor({'z/last', 'a/first'}),
        ['a/first', 'z/last'],
      );
    });
  });

  group('monitorDigestProvider', () {
    test('should expose local digest when repository returns data', () async {
      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(
            const LocalMonitorRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(monitorDigestProvider.future);

      expect(digest.monitoredRepos, isNotEmpty);
      expect(digest.alerts, isEmpty, reason: 'seed data must not fabricate alerts');
      expect(digest.stats.monitoredCount, greaterThan(0));
      expect(digest.isEmpty, isFalse);
    });

    test('should propagate AppException when repository throws', () async {
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenThrow(
        Exception('boom'),
      );

      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(repo),
          monitorAlertEventsProvider.overrideWith(
            () => _FakeMonitorAlertEventsController(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(monitorDigestProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('should expose empty digest when repository returns no data', () async {
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => const DataResult(
          freshness: DataFreshness.seed,
          data: MonitorDigest(
            monitoredRepos: [],
            alerts: [],
            stats: MonitorStats(
              monitoredCount: 0,
              monitoredDelta: 0,
              unreadAlertCount: 0,
              unreadAlertDelta: 0,
              triggeredTodayCount: 0,
              triggeredTodayDelta: 0,
              totalAlertCount: 0,
              totalAlertDelta: 0,
            ),
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(monitorDigestProvider.future);

      expect(digest.isEmpty, isTrue);
      expect(digest.monitoredRepos, isEmpty);
    });

    test('repoByFullName should match decoded fullName', () async {
      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(
            const LocalMonitorRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(monitorDigestProvider.future);
      final first = digest.monitoredRepos.first;
      final encoded = Uri.encodeComponent(first.fullName);

      expect(
        digest.repoByFullName(encoded)?.fullName,
        first.fullName,
      );
    });
  });

  group('monitor search', () {
    test('filterMonitorRepos should match repo name description and language', () {
      final repos = [
        _repo('openai/codex', language: 'TypeScript'),
        _repo(
          'modelcontextprotocol/servers',
          description: 'MCP server collection',
          language: 'Python',
        ),
      ];

      expect(filterMonitorRepos(repos, '').length, 2);
      expect(filterMonitorRepos(repos, 'codex'), [repos.first]);
      expect(filterMonitorRepos(repos, 'mcp'), [repos.last]);
      expect(filterMonitorRepos(repos, 'python'), [repos.last]);
      expect(filterMonitorRepos(repos, 'missing'), isEmpty);
    });

    test('filterMonitorAlerts should match alert fields', () {
      const alerts = [
        AlertEntity(
          repoFullName: 'openai/codex',
          metric: 'Star 增速异常',
          value: '+240',
          time: '10 分钟前',
          severity: AlertSeverity.warning,
        ),
        AlertEntity(
          repoFullName: 'vercel/next.js',
          metric: 'Fork 增速',
          value: '+52',
          time: '1 小时前',
          severity: AlertSeverity.info,
        ),
      ];

      expect(filterMonitorAlerts(alerts, '').length, 2);
      expect(filterMonitorAlerts(alerts, 'star'), [alerts.first]);
      expect(filterMonitorAlerts(alerts, 'next'), [alerts.last]);
      expect(filterMonitorAlerts(alerts, 'info'), [alerts.last]);
      expect(filterMonitorAlerts(alerts, 'missing'), isEmpty);
    });

    test('filteredMonitorDigestProvider should filter current digest', () async {
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => DataResult(
          freshness: DataFreshness.live,
          data: MonitorDigest(
            monitoredRepos: [
              _repo('openai/codex', language: 'TypeScript'),
              _repo('vercel/next.js', language: 'JavaScript'),
            ],
            alerts: const [
              AlertEntity(
                repoFullName: 'openai/codex',
                metric: 'Star 增速异常',
                value: '+240',
                time: '10 分钟前',
                severity: AlertSeverity.warning,
              ),
            ],
            stats: _stats,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(repo),
          monitorAlertEventsProvider.overrideWith(
            () => _FakeMonitorAlertEventsController([
              MonitorAlertEvent(
                id: 'codex-alert',
                repoFullName: 'openai/codex',
                ruleId: MonitorRuleIds.starDailyDelta,
                metric: 'stars',
                value: 240,
                threshold: 200,
                severity: AlertSeverity.warning,
                observedAt: DateTime.utc(2026, 7, 3),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(monitorSearchQueryProvider.notifier).state = 'codex';
      final digest = await container.read(filteredMonitorDigestProvider.future);

      expect(digest.monitoredRepos.single.fullName, 'openai/codex');
      expect(digest.alerts.single.repoFullName, 'openai/codex');
      expect(digest.stats.monitoredCount, 2);
      verify(repo.getDigest).called(1);
    });

    test('visibleMonitorDigestProvider merges durable alert state', () async {
      final now = DateTime.utc(2026, 7, 3, 12);
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => DataResult(
          freshness: DataFreshness.live,
          data: MonitorDigest(
            monitoredRepos: [_repo('openai/codex')],
            alerts: const [],
            stats: _stats,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          monitorRepositoryProvider.overrideWithValue(repo),
          monitorAlertEventsProvider.overrideWith(
            () => _FakeMonitorAlertEventsController([
              MonitorAlertEvent(
                id: 'visible',
                repoFullName: 'openai/codex',
                ruleId: MonitorRuleIds.starDailyDelta,
                metric: 'stars',
                value: 200,
                threshold: 200,
                severity: AlertSeverity.warning,
                observedAt: now,
              ),
            ]),
          ),
          monitorAlertClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      final digest = await container.read(visibleMonitorDigestProvider.future);

      expect(digest.alerts.single.id, 'visible');
      expect(digest.stats.unreadAlertCount, 1);
    });

    test('monitorDigestResultProvider exposes response freshness', () async {
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => DataResult(
          freshness: DataFreshness.staleCache,
          data: MonitorDigest(
            monitoredRepos: [_repo('openai/codex')],
            alerts: const [],
            stats: _stats,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [monitorRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(monitorDigestResultProvider.future);

      expect(result.freshness, DataFreshness.staleCache);
      expect(result.data.monitoredRepos.single.fullName, 'openai/codex');
    });

    test('applyMonitorAlertEvents restores durable visible alert state', () {
      final now = DateTime.utc(2026, 7, 3, 12);
      final digest = applyMonitorAlertEvents(
        MonitorDigest(
          monitoredRepos: [_repo('openai/codex')],
          alerts: const [],
          stats: _stats,
        ),
        [
          MonitorAlertEvent(
            id: 'visible',
            repoFullName: 'openai/codex',
            ruleId: MonitorRuleIds.starDailyDelta,
            metric: 'stars',
            value: 200,
            threshold: 200,
            severity: AlertSeverity.warning,
            observedAt: now,
          ),
          MonitorAlertEvent(
            id: 'archived',
            repoFullName: 'openai/codex',
            ruleId: MonitorRuleIds.forkDailyDelta,
            metric: 'forks',
            value: 50,
            threshold: 50,
            severity: AlertSeverity.info,
            observedAt: now,
            archivedAt: now,
          ),
        ],
        now,
      );

      expect(digest.alerts.single.id, 'visible');
      expect(digest.stats.unreadAlertCount, 1);
      expect(digest.stats.totalAlertCount, 1);
    });

    test('unread filter reads durable timestamps from alert entities', () {
      final alerts = [
        AlertEntity(
          id: 'unread',
          repoFullName: 'openai/codex',
          metric: MonitorRuleIds.starDailyDelta,
          value: '+200',
          time: '刚刚',
          severity: AlertSeverity.warning,
          observedAt: DateTime.utc(2026, 7, 3),
        ),
        AlertEntity(
          id: 'read',
          repoFullName: 'openai/codex',
          metric: MonitorRuleIds.forkDailyDelta,
          value: '+50',
          time: '刚刚',
          severity: AlertSeverity.info,
          observedAt: DateTime.utc(2026, 7, 3),
          readAt: DateTime.utc(2026, 7, 3, 1),
        ),
      ];

      expect(
        filterAlertsByState(alerts, MonitorAlertFilter.unread),
        [alerts.first],
      );
    });
  });
}
