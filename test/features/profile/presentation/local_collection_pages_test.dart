import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/profile/presentation/collect_page.dart';
import 'package:github_news/features/profile/presentation/followed_developers_page.dart';
import 'package:github_news/features/profile/presentation/monitor_topics_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('collection pages render persisted remote snapshots', (tester) async {
    final prefs = await _preferences();

    await _pump(tester, prefs, const CollectPage());
    expect(find.text('remote/new-repo'), findsOneWidget);
    expect(find.text('Only returned by GitHub'), findsOneWidget);

    await _pump(tester, prefs, const MonitorTopicsPage());
    expect(find.text('remote/new-repo'), findsOneWidget);

    await _pump(tester, prefs, const FollowedDevelopersPage());
    expect(find.text('remote-dev'), findsOneWidget);
    expect(find.textContaining('19'), findsOneWidget);
  });
}

Future<SharedPreferences> _preferences() async {
  SharedPreferences.setMockInitialValues({
    'local_content_bookmarked_repos': ['remote/new-repo'],
    'local_content_monitored_repos': ['remote/new-repo'],
    'local_content_followed_developers': ['remote-dev'],
    'local_content_repo_snapshots_v1': jsonEncode(
      [
        {
          'fullName': 'remote/new-repo',
          'description': 'Only returned by GitHub',
          'language': 'Rust',
          'starCount': 42,
          'forkCount': 7,
          'accentArgb': 0xFFDEA584,
          'updatedAt': '2026-07-11T00:00:00.000Z'
        }
      ],
    ),
    'local_content_developer_snapshots_v1': jsonEncode(
      [
        {'login': 'remote-dev', 'contributions': 19, 'avatarAccentArgb': 0xFF6366F1, 'updatedAt': '2026-07-11T00:00:00.000Z'}
      ],
    )
  });
  return SharedPreferences.getInstance();
}

Future<void> _pump(WidgetTester tester, SharedPreferences prefs, Widget page) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
