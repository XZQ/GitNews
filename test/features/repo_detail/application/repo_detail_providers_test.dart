import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/repo_detail/application/repo_detail_providers.dart';

void main() {
  test('should expose local repo detail digest when provider is read',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final digest = await container.read(
      repoDetailDigestProvider('denoland/deno').future,
    );

    expect(digest.repo.fullName, 'denoland/deno');
    expect(digest.contributors, isNotEmpty);
    expect(digest.relatedRepos, isNotEmpty);
    expect(digest.primaryTrend, isNotEmpty);
    expect(digest.compareTrend, isNotEmpty);
  });
}
