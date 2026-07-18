import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/repo_detail/domain/repo_detail_repository.dart';
import 'package:github_news/features/repo_detail/presentation/detail/repo_detail_chart.dart';
import 'package:github_news/features/repo_detail/presentation/detail/repo_detail_stats.dart';

void main() {
  const repo = RepoEntity(
    fullName: 'very-long-organization/very-long-repository-name',
    description: 'A repository description',
    language: 'Dart',
    starCount: 527000,
    starDelta: 4400,
    forkCount: 49900,
    accentArgb: 0xFF0D9488,
    valueBasis: MetricBasis.observed,
    trendBasis: MetricBasis.estimated,
    trend: [520000, 521000, 522500, 524000, 526000, 527000],
  );

  const digest = RepoDetailDigest(
    repo: repo,
    contributors: [],
    relatedRepos: [],
    primaryTrend: [520000, 521000, 522500, 524000, 526000, 527000],
    compareTrend: [510000, 512000, 514000, 516000, 518000, 520000],
    activities: [],
  );

  testWidgets('手机指标使用两列且数字保持单行', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _TestApp(child: RepoDetailStats(repo: repo, contributorCount: 128)));
    await tester.pumpAndSettle();

    final firstMetric = tester.getTopLeft(find.text('527.0k'));
    final thirdMetric = tester.getTopLeft(find.text('49.9k'));
    expect(thirdMetric.dy, greaterThan(firstMetric.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面指标保持四列', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _TestApp(child: RepoDetailStats(repo: repo, contributorCount: 128)));
    await tester.pumpAndSettle();

    final firstMetric = tester.getTopLeft(find.text('527.0k'));
    final thirdMetric = tester.getTopLeft(find.text('49.9k'));
    expect((thirdMetric.dy - firstMetric.dy).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机趋势标题、口径和时间窗不会横向溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _TestApp(child: RepoDetailChart(digest: digest)));
    await tester.pumpAndSettle();

    expect(find.text('7天'), findsOneWidget);
    expect(find.text('30天'), findsOneWidget);
    expect(find.text('90天'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/*
*为仓库详情响应式组件提供中文本地化和稳定页面边距。
*/
class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  // 待测详情组件。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
