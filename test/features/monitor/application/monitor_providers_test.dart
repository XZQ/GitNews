import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockMonitorRepository extends Mock implements MonitorRepository {}

void main() {
  group('monitorDigestProvider', () {
    test('should expose local digest when repository returns data', () async {
      final container = ProviderContainer();
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
      final container = ProviderContainer();
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
}
