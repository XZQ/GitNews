import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/monitor/application/monitor_providers.dart';

void main() {
  test('should expose local monitor digest when provider is read', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final digest = await container.read(monitorDigestProvider.future);

    expect(digest.monitoredRepos, isNotEmpty);
    expect(digest.alerts, isNotEmpty);
    expect(digest.stats.monitoredCount, greaterThan(0));
    expect(digest.isEmpty, isFalse);
  });
}
