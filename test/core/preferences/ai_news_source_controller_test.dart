import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/ai_news_sources_config.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/ai_news_source_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('first launch enables every built-in source', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final state = container.read(aiNewsSourceControllerProvider);

    expect(state.entries, hasLength(AiNewsSourcesConfig.sources.length));
    expect(state.enabledCount, AiNewsSourcesConfig.sources.length);
    expect(state.entries.every((entry) => !entry.isCustom), isTrue);
  });

  test('custom source and enabled state persist across containers', () async {
    final first = await _container();
    final controller = first.read(aiNewsSourceControllerProvider.notifier);

    await controller.setEnabled('openai_news', false);
    await controller.addCustom(
      name: 'Example AI',
      feedUrl: 'https://example.com/feed.xml#latest',
      categoryCode: 'industry',
    );
    first.dispose();

    final prefs = await SharedPreferences.getInstance();
    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    final state = second.read(aiNewsSourceControllerProvider);
    final custom = state.entries.singleWhere((entry) => entry.isCustom);

    expect(
      state.entries.singleWhere((entry) => entry.config.id == 'openai_news').enabled,
      isFalse,
    );
    expect(custom.config.name, 'Example AI');
    expect(custom.config.feedUrl, 'https://example.com/feed.xml');
    expect(custom.enabled, isTrue);
  });

  test('source health degrades after failures and recovers on success', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final controller = container.read(aiNewsSourceControllerProvider.notifier);
    final failureAt = DateTime.utc(2026, 7, 16, 1);

    for (var index = 0; index < 3; index++) {
      await controller.reportFailure(
        'openai_news',
        failureAt.add(Duration(minutes: index)),
        StateError('offline'),
      );
    }

    var source = container.read(aiNewsSourceControllerProvider).entries.singleWhere((entry) => entry.config.id == 'openai_news');
    expect(source.health.consecutiveFailures, 3);
    expect(source.health.isDegraded, isTrue);
    expect(source.health.lastError, 'StateError');

    final successAt = DateTime.utc(2026, 7, 16, 2);
    await controller.reportSuccess('openai_news', successAt);
    source = container.read(aiNewsSourceControllerProvider).entries.singleWhere((entry) => entry.config.id == 'openai_news');
    expect(source.health.consecutiveFailures, 0);
    expect(source.health.isDegraded, isFalse);
    expect(source.health.lastSuccessAt, successAt);
    expect(source.health.lastError, isNull);
  });

  test('invalid source documents are rejected before import', () {
    expect(
      () => validateAiNewsSourcesPreference(
        '[{"id":"bad","name":"Bad","feedUrl":"file:///tmp/feed",'
        '"categoryCode":"industry","isCustom":true}]',
      ),
      throwsFormatException,
    );
  });
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}
