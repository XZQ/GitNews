import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_activity_event.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/profile/presentation/collect_page.dart';
import 'package:github_news/features/profile/presentation/login_page.dart';
import 'package:github_news/features/project/presentation/widgets/activity_events_card.dart';
import 'package:github_news/features/tech_hotspot/presentation/widgets/tech_hotspot_tags_cloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in const [Size(1366, 768), Size(1024, 768), Size(390, 844)]) {
    testWidgets('trust flows fit ${size.width.toInt()}px', (tester) async {
      final semantics = tester.ensureSemantics();
      final prefs = await _preferences();
      await _pumpAtSize(tester, size, prefs, const CollectPage());
      expect(find.text('Starred topics'), findsWidgets);
      expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpAtSize(
        tester,
        size,
        prefs,
        ActivityEventsCard(
          activities: [
            RepoActivityEvent(
              repoFullName: 'owner/a-very-long-repository-name',
              type: RepoActivityType.release,
              title: 'Published a release with a deliberately long title',
              actorLogin: 'octocat',
              occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
              htmlUrl: null,
              basis: MetricBasis.observed,
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel(RegExp(r'Open owner/a-very-long-repository-name')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpAtSize(tester, size, prefs, TechHotspotTagsCloud(tags: const [], onTagSelected: (_) {}));
      expect(find.text('No matching radar tags'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpAtSize(tester, size, prefs, const LoginPage());
      expect(find.text('Sign in with phone'), findsOneWidget);
      expect(find.text('Continue anonymously'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('bookmark removal is keyboard activatable', (tester) async {
    final prefs = await _preferences();
    await _pumpAtSize(tester, const Size(1024, 768), prefs, const CollectPage());
    final removeIcon = find.byIcon(Icons.bookmark_remove_outlined);

    Focus.of(tester.element(removeIcon)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('No starred topics yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<SharedPreferences> _preferences() async {
  SharedPreferences.setMockInitialValues({
    'local_content_bookmarked_repos': ['remote/new-repo'],
    'local_content_monitored_repos': <String>[],
    'local_content_followed_developers': <String>[],
    'local_content_repo_snapshots_v1': jsonEncode([
      {'fullName': 'remote/new-repo', 'description': 'Only returned by GitHub', 'language': 'Rust', 'starCount': 42, 'forkCount': 7, 'accentArgb': 0xFFDEA584, 'updatedAt': '2026-07-11T00:00:00.000Z'},
    ]),
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpAtSize(WidgetTester tester, Size size, SharedPreferences preferences, Widget child) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
