import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/repository_feed_providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repository_feed.dart';

/*
 *`repositoryFeedProvider` 是 core 对 feature 的依赖倒置点:
 *core 只声明契约,实现由组合根注入(`lib/app/di/app_overrides.dart`)。
 *
 *缺省实现必须显式抛错,否则忘记装配时会静默拿到空数据,把「没接线」伪装成
 *「没有仓库」。
 */
void main() {
  test('repositoryFeedProvider has no default implementation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Riverpod 3 会把 provider 内部抛出的异常包成 ProviderException,所以断言错误文案而不是类型。
    expect(() => container.read(repositoryFeedProvider), throwsA(predicate((error) => error.toString().contains('must be overridden'), 'mentions the override contract')));
  });

  test('repositoryFeedProvider is replaceable by the composition root', () {
    final container = ProviderContainer(overrides: [repositoryFeedProvider.overrideWithValue(_EmptyRepositoryFeed())]);
    addTearDown(container.dispose);
    expect(container.read(repositoryFeedProvider), isA<_EmptyRepositoryFeed>());
  });
}

class _EmptyRepositoryFeed implements RepositoryFeed {
  @override
  Future<DataResult<RepositoryFeedDigest>> load() async {
    return const DataResult(
      data: RepositoryFeedDigest(repos: [], primaryTrend: [], secondaryTrend: []),
      freshness: DataFreshness.seed,
    );
  }
}
