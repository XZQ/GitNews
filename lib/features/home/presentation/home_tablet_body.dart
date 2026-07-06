import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../trending/application/trending_providers.dart';
import '../widgets/home_topics_panel.dart';
import 'home_chart_helpers.dart';
import 'home_tablet_metrics_row.dart';
import 'home_today_stack.dart';

/// Home medium (600–1024) 分支:指标行 + 主图表 + 主题。
class HomeTabletBody extends StatelessWidget {
  const HomeTabletBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: const [
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
    final digest = ref.watch(trendingDigestProvider).valueOrNull;
    final series = homeSeriesForWindow(
      _chartWindow,
      widget.tab,
      Theme.of(context).colorScheme.primary,
      primaryTrend: digest?.primaryTrend,
      secondaryTrend: digest?.secondaryTrend,
    );
    final windowLabel = '近 $_chartWindow 天';
    final title = homeChartTitle(widget.tab);
    final subtitle = homeChartSubtitle(widget.tab, windowLabel);
    final legends =
        homeChartLegends(widget.tab, Theme.of(context).colorScheme.primary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(title: title, subtitle: subtitle),
              ),
              ChartWindowSegmented(
                value: _chartWindow,
                onChanged: (v) => setState(() => _chartWindow = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < legends.length; i++) ...[
                HomeLegendDot(color: legends[i].color, label: legends[i].label),
                if (i != legends.length - 1)
                  const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StarTrendChart(series: series, height: 280),
        ],
      ),
    );
  }
}
