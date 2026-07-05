import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/monitor/application/monitor_alert_state_controller.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/data/local_monitor_repository.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMonitorRepository extends Mock implements MonitorRepository {}

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
      expect(digest.alerts, isNotEmpty);
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
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(monitorDigestProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('should expose empty digest when repository returns no data',
        () async {
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => const MonitorDigest(
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
    test('filterMonitorRepos should match repo name description and language',
        () {
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

    test('filteredMonitorDigestProvider should filter current digest',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _MockMonitorRepository();
      when(repo.getDigest).thenAnswer(
        (_) async => MonitorDigest(
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
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          monitorRepositoryProvider.overrideWithValue(repo),
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

    test('applyMonitorAlertState should hide archived alerts and update stats',
        () {
      const alerts = [
        AlertEntity(
          repoFullName: 'openai/codex',
          metric: 'Star growth',
          value: '+240',
          time: '10 min ago',
          severity: AlertSeverity.warning,
        ),
        AlertEntity(
          repoFullName: 'vercel/next.js',
          metric: 'Fork growth',
          value: '+52',
          time: '1 hour ago',
          severity: AlertSeverity.info,
        ),
      ];
      final state = MonitorAlertState(
        readAlertIds: {alertStableId(alerts.first)},
        archivedAlertIds: {alertStableId(alerts.last)},
      );

      final digest = applyMonitorAlertState(
        MonitorDigest(
          monitoredRepos: [_repo('openai/codex')],
          alerts: alerts,
          stats: _stats,
        ),
        state,
      );

      expect(digest.alerts, [alerts.first]);
      expect(digest.stats.unreadAlertCount, 0);
      expect(digest.stats.totalAlertCount, 1);
    });
  });
}
