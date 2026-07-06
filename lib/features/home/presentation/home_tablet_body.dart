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
class HomeTabletBody extends StatefulWidget {
  const HomeTabletBody({super.key});

  @override
  State<HomeTabletBody> createState() => _HomeTabletBodyState();
}

class _HomeTabletBodyState extends State<HomeTabletBody> {
  int _chartWindow = 7;
  final HomeLegacyTab _tab = HomeLegacyTab.trending;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        HomeTabletMetricsRow(tab: _tab),
        const SizedBox(height: AppSpacing.lg),
        _DesktopMainLayout(
          chartWindow: _chartWindow,
          onChartWindowChanged: (v) => setState(() => _chartWindow = v),
          tab: _tab,
        ),
        const SizedBox(height: AppSpacing.lg),
        const HomeTopicsPanel(),
      ],
    );
  }
}

class _DesktopMainLayout extends StatelessWidget {
  const _DesktopMainLayout({
    required this.chartWindow,
    required this.onChartWindowChanged,
    required this.tab,
  });

  final int chartWindow;
  final ValueChanged<int> onChartWindowChanged;
  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 8,
            child: _ChartCard(
              window: chartWindow,
              onChanged: onChartWindowChanged,
              tab: tab,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: HomeTodayStack(tab: tab)),
        ],
      ),
    );
  }
}

class _ChartCard extends ConsumerWidget {
  const _ChartCard({
    required this.window,
    required this.onChanged,
    required this.tab,
  });
  final int window;
  final ValueChanged<int> onChanged;
  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(trendingDigestProvider).valueOrNull;
    final series = homeSeriesForWindow(
      window,
      tab,
      Theme.of(context).colorScheme.primary,
      primaryTrend: digest?.primaryTrend,
      secondaryTrend: digest?.secondaryTrend,
    );
    final windowLabel = '近 $window 天';
    final title = homeChartTitle(tab);
    final subtitle = homeChartSubtitle(tab, windowLabel);
    final legends =
        homeChartLegends(tab, Theme.of(context).colorScheme.primary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(title: title, subtitle: subtitle),
              ),
              ChartWindowSegmented(value: window, onChanged: onChanged),
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
