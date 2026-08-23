import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/repo_detail/presentation/detail/repo_detail_header.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/tech_hotspot/presentation/detail/tech_hotspot_detail_topic_header.dart';
import 'package:github_news/shared/widgets/data_provenance_badge.dart';

void main() {
  final theme = AppTheme.light(AppColors.brand);

  testWidgets('仓库详情浅色标题区使用主题前景色和非反色口径徽章', (tester) async {
    const repo = RepoEntity(
      fullName: 'owner/repository',
      description: 'Repository description',
      language: 'Dart',
      starCount: 100,
      starDelta: 10,
      forkCount: 20,
      accentArgb: 0xFF0D9488,
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.estimated,
    );

    await tester.pumpWidget(
      _TestApp(
        theme: theme,
        child: const RepoDetailHeader(repo: repo, freshness: DataFreshness.live),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text(repo.description)).style?.color, theme.colorScheme.onSurfaceVariant);
    expect(tester.widget<DataFreshnessBadge>(find.byType(DataFreshnessBadge)).inverse, isFalse);
    expect(tester.widget<MetricBasisBadge>(find.byType(MetricBasisBadge)).inverse, isFalse);
  });

  testWidgets('技术热点浅色标题区指标使用主题前景色', (tester) async {
    const topic = TechTopic(id: 'agent', name: 'Agent', category: 'AI', heat: 92, growth: 12.4, mentions: 230, relatedRepos: 42, summary: 'Agent frameworks');

    await tester.pumpWidget(
      _TestApp(
        theme: theme,
        child: const TechHotspotDetailTopicHeader(topic: topic),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Icon>(find.byIcon(Icons.trending_up_rounded)).color, theme.colorScheme.onSurfaceVariant);
    expect(tester.widget<Text>(find.text('+12.4%')).style?.color, theme.colorScheme.onSurface);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.theme, required this.child});

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
