import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';
import 'package:github_news/features/discover/presentation/widgets/discover_profile_row.dart';

DiscoverProfileEntity _profile({bool enriched = true}) => DiscoverProfileEntity(
      login: 'karpathy',
      name: 'Andrej',
      type: 'User',
      bio: enriched ? 'AI researcher' : '',
      publicRepos: enriched ? 60 : 0,
      followers: enriched ? 200000 : 0,
      avatarUrl: '',
      htmlUrl: '',
      featuredRepoFullName: 'karpathy/nanoGPT',
      kind: DiscoverProfileKind.people,
      enriched: enriched,
    );

void main() {
  testWidgets('enriched=false 时显示占位 —', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiscoverProfileRow(profile: _profile(enriched: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('enriched=true 时不显示占位 —', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiscoverProfileRow(profile: _profile(enriched: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNothing);
  });
}
