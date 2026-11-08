import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/app/di/app_overrides.dart';
import 'package:github_news/core/auth/auth_repository.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/di/repository_feed_providers.dart';
import 'package:github_news/core/preferences/config_service.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/monitor/application/monitor_settings_controller.dart';
import 'package:github_news/features/trending/application/trending_repository_feed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
 *组合根装配清单的守卫。
 *
 *`buildAppOverrides` 是应用唯一一处注入实现的地方:漏掉任何一条 override,
 *对应的占位 provider 就会在运行时抛错,而不是在编译期暴露。这里把
 *「哪些 provider 必须被装配」显式写下来,漏一条即测试失败。
 */
void main() {
  late SharedPreferences preferences;
  late LocalDatabase database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    database = await LocalDatabase.openInMemory();
  });

  tearDown(() async {
    await database.close();
  });

  List<Override> buildOverrides() => buildAppOverrides(preferences: preferences, database: database, authRepository: const UnconfiguredAuthRepository());

  test('every placeholder provider is overridden by the composition root', () {
    final origins = buildOverrides().map((override) => override.origin).whereType<Object>().toSet();

    // 这三个 provider 的缺省实现都会抛错,必须由组合根注入。
    expect(origins, contains(sharedPreferencesProvider));
    expect(origins, contains(appDatabaseProvider));
    expect(origins, contains(authRepositoryProvider));
    expect(origins, contains(repositoryFeedProvider));
    expect(origins, contains(configInvalidationHooksProvider));
  });

  test('the composition root does not override unrelated providers', () {
    final origins = buildOverrides().map((override) => override.origin).whereType<Object>().toSet();

    // 覆盖无关 provider 属于装配越界:组合根只负责「core 需要但 core 不能自己造」的能力。
    expect(origins, isNot(contains(dioProvider)));
  });

  test('overridden providers resolve without throwing', () {
    final container = ProviderContainer(overrides: buildOverrides());
    addTearDown(container.dispose);

    expect(container.read(sharedPreferencesProvider), same(preferences));
    expect(container.read(appDatabaseProvider), same(database));
    expect(container.read(authRepositoryProvider), isA<UnconfiguredAuthRepository>());
    expect(container.read(repositoryFeedProvider), isA<TrendingRepositoryFeed>());
  });

  test('the repository feed override is wired to the trending feed adapter', () {
    final container = ProviderContainer(overrides: buildOverrides());
    addTearDown(container.dispose);

    // 组合根把 trending 的 feed 适配器注入 core 的抽象契约。
    expect(container.read(repositoryFeedProvider), isA<TrendingRepositoryFeed>());
  });

  test('the config invalidation hook list is not empty', () {
    final container = ProviderContainer(overrides: buildOverrides());
    addTearDown(container.dispose);

    final hooks = container.read(configInvalidationHooksProvider);

    expect(hooks, isNotEmpty, reason: '导入配置后必须至少失效 monitor 的偏好项');
  });

  test('the invalidation hook actually invalidates the monitor settings', () async {
    final container = ProviderContainer(overrides: buildOverrides());
    addTearDown(container.dispose);

    // 先读一次,让 monitor 设置进入缓存,后续才能观察到失效后的重新读取。
    expect(container.read(monitorSettingsControllerProvider), [true]);

    await preferences.setStringList('monitor_notification_settings', ['0']);
    expect(container.read(monitorSettingsControllerProvider), [true], reason: '未失效前应命中缓存');

    // 组合根注册的钩子通过 ref.invalidate 让 feature 侧的偏好项失效。
    container.read(_invalidationProbeProvider);

    expect(container.read(monitorSettingsControllerProvider), [false]);
  });
}

/// 在 provider 内部执行钩子:钩子拿到的是真实的 `Ref`,与生产路径一致。
final _invalidationProbeProvider = Provider<void>((ref) {
  for (final hook in ref.read(configInvalidationHooksProvider)) {
    hook(ref);
  }
});
