import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/shared/local_content_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('should toggle local content and persist settings', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    final notifier = container.read(localContentControllerProvider.notifier);
    await notifier.toggleBookmark('openai/codex');
    await notifier.addMonitor('openai/codex');
    await notifier.toggleDeveloper('octocat');
    await notifier.setMonitorRule(2, true);

    final state = container.read(localContentControllerProvider);
    expect(state.isBookmarked('openai/codex'), isTrue);
    expect(state.isMonitored('openai/codex'), isTrue);
    expect(state.isFollowingDeveloper('octocat'), isTrue);
    expect(state.monitorRules[2], isTrue);

    final restored = await _container();
    addTearDown(restored.dispose);
    final restoredState = restored.read(localContentControllerProvider);
    expect(restoredState.isBookmarked('openai/codex'), isTrue);
    expect(restoredState.isMonitored('openai/codex'), isTrue);
    expect(restoredState.isFollowingDeveloper('octocat'), isTrue);
    expect(restoredState.monitorRules[2], isTrue);
  });
}

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}
