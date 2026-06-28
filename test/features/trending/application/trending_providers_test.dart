import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';

void main() {
  test('should expose local trending digest when provider is read', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final digest = await container.read(trendingDigestProvider.future);

    expect(digest.trendingRepos, isNotEmpty);
    expect(digest.recentRepos, isNotEmpty);
    expect(digest.languages, isNotEmpty);
    expect(digest.primaryTrend, isNotEmpty);
    expect(digest.isEmpty, isFalse);
  });
}
