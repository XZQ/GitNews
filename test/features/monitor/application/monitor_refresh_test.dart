import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/provider_retry_policy.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';
import 'package:github_news/features/monitor/domain/entities.dart';
import 'package:github_news/features/monitor/domain/monitor_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements MonitorRepository {}

const _digest = MonitorDigest(
  monitoredRepos: [],
  alerts: [],
  stats: MonitorStats(monitoredCount: 0, monitoredDelta: 0, unreadAlertCount: 0, unreadAlertDelta: 0, triggeredTodayCount: 0, triggeredTodayDelta: 0, totalAlertCount: 0, totalAlertDelta: 0),
);

void main() {
  test('refresh publishes the forced result and merges repeated clicks without another read', () async {
    final repository = _Repository();
    const original = DataResult(data: _digest, freshness: DataFreshness.freshCache);
    const failed = DataResult(data: _digest, freshness: DataFreshness.staleCache);
    final pending = Completer<DataResult<MonitorDigest>>();
    when(() => repository.getDigest()).thenAnswer((_) async => original);
    when(() => repository.getDigest(force: true)).thenAnswer((_) => pending.future);
    final container = ProviderContainer.test(overrides: [monitorRepositoryProvider.overrideWithValue(repository)]);
    final subscription = container.listen(monitorDigestResultProvider, (_, __) {});
    addTearDown(subscription.close);
    expect(await container.read(monitorDigestResultProvider.future), same(original));
    final controller = container.read(monitorDigestResultProvider.notifier);
    final first = controller.refresh();
    final second = controller.refresh();
    expect(container.read(monitorRefreshInProgressProvider), isTrue);
    expect(container.read(monitorDigestResultProvider).value, same(original));
    pending.complete(failed);
    await Future.wait([first, second]);
    expect(await container.read(monitorDigestResultProvider.future), same(failed));
    expect(container.read(monitorRefreshInProgressProvider), isFalse);
    verify(() => repository.getDigest()).called(1);
    verify(() => repository.getDigest(force: true)).called(1);
  });

  test('failed refresh releases its task so the next retry can recover', () async {
    final repository = _Repository();
    const result = DataResult(data: _digest, freshness: DataFreshness.live);
    when(() => repository.getDigest()).thenAnswer((_) async => result);
    when(() => repository.getDigest(force: true)).thenThrow(StateError('simulated storage failure'));
    final container = ProviderContainer.test(retry: noProviderRetry, overrides: [monitorRepositoryProvider.overrideWithValue(repository)]);
    await container.read(monitorDigestResultProvider.future);
    final controller = container.read(monitorDigestResultProvider.notifier);
    await expectLater(controller.refresh(), throwsStateError);
    expect(container.read(monitorRefreshInProgressProvider), isFalse);
    when(() => repository.getDigest(force: true)).thenAnswer((_) async => result);
    await controller.refresh();
    expect(await container.read(monitorDigestResultProvider.future), same(result));
  });
}
