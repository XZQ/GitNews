import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/project/presentation/widgets/project_language_distribution.dart';

RepoEntity _repo(int index) {
  return RepoEntity(
    fullName: 'owner/repo$index',
    description: 'Repository $index',
    language: 'LanguageWithLongName$index',
    starCount: 1000 + index,
    starDelta: 10,
    forkCount: 20,
    accentArgb: 0xFF3178C6 + index,
  );
}

void main() {
  testWidgets('language distribution scrolls inside bounded card',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(760, 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 680,
              height: 220,
              child: ProjectLanguageDistribution(
                repos: [for (var i = 0; i < 12; i++) _repo(i)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProjectLanguageDistribution), findsOneWidget);
  });
}
