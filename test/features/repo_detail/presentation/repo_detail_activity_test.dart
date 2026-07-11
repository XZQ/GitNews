import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_activity_event.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/repo_detail/presentation/detail/repo_detail_activity.dart';
import 'package:github_news/shared/widgets/empty_view.dart';

void main() {
  testWidgets('renders only supplied real repository activity', (tester) async {
    await _pump(
      tester,
      RepoDetailActivity(
        activities: [
          RepoActivityEvent(
            repoFullName: 'owner/repo',
            type: RepoActivityType.push,
            title: 'feat: trusted activity',
            actorLogin: 'octocat',
            occurredAt: DateTime.now().toUtc(),
            htmlUrl: 'https://github.com/owner/repo/commit/abc',
            basis: MetricBasis.observed,
          ),
        ],
      ),
    );

    expect(find.text('feat: trusted activity'), findsOneWidget);
    expect(find.textContaining('octocat'), findsOneWidget);
    expect(find.text('fix: cache invalidation race'), findsNothing);
  });

  testWidgets('renders an empty state when GitHub returns no activity', (
    tester,
  ) async {
    await _pump(tester, const RepoDetailActivity(activities: []));

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('feat: support streaming response'), findsNothing);
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
