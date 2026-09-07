import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_growth_chart.dart';
import '../../../shared/widgets/section_header.dart';
import '../../trending/application/trending_providers.dart';
import '../widgets/home_ai_hot_topics_card.dart';
import '../widgets/home_topics_panel.dart';
import 'home_chart_models.dart';
import 'home_chart_widgets.dart';
import 'home_tablet_metrics_row.dart';
import 'home_today_stack.dart';

/* 
*Home medium (600–1024) 分支:当前热点 + 指标行 + 主图表 + 主题。
*/
class HomeTabletBody extends StatelessWidget {
  const HomeTabletBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: const [
        HomeAiHotTopicsCard(),
        SizedBox(height: AppSpacing.lg),
        HomeTabletMetricsRow(tab: HomeLegacyTab.trending),
        SizedBox(height: AppSpacing.lg),
        _DesktopMainLayout(tab: HomeLegacyTab.trending),
        SizedBox(height: AppSpacing.lg),
        HomeTopicsPanel(),
      ],
    );
  }
}

class _DesktopMainLayout extends StatelessWidget {
  const _DesktopMainLayout({required this.tab});
  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: _ChartCard(tab: tab)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: HomeTodayStack(tab: tab)),
        ],
      ),
    );
  }
}

class _ChartCard extends ConsumerStatefulWidget {
  const _ChartCard({required this.tab});
  final HomeLegacyTab tab;

  @override
  ConsumerState<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends ConsumerState<_ChartCard> {
  int _chartWindow = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digest = ref.watch(trendingDigestProvider).value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(title: l10n.tr('growth.title'), subtitle: l10n.tr('growth.subtitle')),
              ),
              ChartWindowSegmented(value: _chartWindow, onChanged: (v) => setState(() => _chartWindow = v)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RepoGrowthChart(repos: digest?.allRepos ?? const [], days: _chartWindow, height: 180),
        ],
      ),
    );
  }
}
