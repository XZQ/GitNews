import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/profile_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ProfileSessionController should default to anonymous', () async {
    final container = await _container();

    final state = container.read(profileSessionControllerProvider);

    expect(state.isSignedIn, isFalse);
    expect(state.effectiveName, 'dev_explorer');
  });

  test('ProfileSessionController should persist local sign in and sign out', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(profileSessionControllerProvider.notifier).signInLocal('  XZQ  ');

    expect(prefs.getString('profile_display_name'), 'XZQ');
    expect(container.read(profileSessionControllerProvider).isSignedIn, isTrue);
    expect(
      container.read(profileSessionControllerProvider).effectiveName,
      'XZQ',
    );

    await container.read(profileSessionControllerProvider.notifier).signOut();

    expect(prefs.getString('profile_display_name'), isNull);
    expect(
      container.read(profileSessionControllerProvider).isSignedIn,
      isFalse,
    );
  });
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}
