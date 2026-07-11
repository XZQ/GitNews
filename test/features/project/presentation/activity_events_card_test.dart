import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_activity_event.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/project/presentation/widgets/activity_events_card.dart';
import 'package:github_news/shared/widgets/empty_view.dart';

void main() {
  testWidgets('project activity card renders supplied observed events only', (
    tester,
  ) async {
    await _pump(
      tester,
      ActivityEventsCard(
        activities: [
          RepoActivityEvent(
            repoFullName: 'owner/repo',
            type: RepoActivityType.release,
            title: 'published: v1.3.0',
            actorLogin: 'octocat',
            occurredAt: DateTime.now().toUtc(),
            htmlUrl: 'https://github.com/owner/repo/releases/v1.3.0',
            basis: MetricBasis.observed,
          ),
        ],
      ),
    );

    expect(find.text('owner/repo'), findsOneWidget);
    expect(find.text('published: v1.3.0'), findsOneWidget);
    expect(find.text('演示数据'), findsNothing);
    expect(find.text('feat: support streaming response'), findsNothing);
  });

  testWidgets('project activity card shows an empty state without events', (
    tester,
  ) async {
    await _pump(tester, const ActivityEventsCard(activities: []));

    expect(find.byType(EmptyView), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
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
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}
