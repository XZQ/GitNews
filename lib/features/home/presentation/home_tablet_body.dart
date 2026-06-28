import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../widgets/home_topics_panel.dart';
import 'home_chart_helpers.dart';
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
        _OverviewMetricsRow(tab: _tab),
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

class _OverviewMetricsRow extends StatelessWidget {
  const _OverviewMetricsRow({required this.tab});

  final HomeLegacyTab tab;

  List<HomeMetricSpec> _specsFor(HomeLegacyTab tab, Color primary) {
    switch (tab) {
      case HomeLegacyTab.trending:
        return [
          const HomeMetricSpec(
            title: '今日新增 Star',
            value: '128',
            delta: '+18.5%',
            subtitle: '对比昨日',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const HomeMetricSpec(
            title: 'Star 增长榜仓库',
            value: '42.8K',
            delta: '+7.2%',
            subtitle: '趋势榜首',
            icon: Icons.trending_up_rounded,
          ),
          const HomeMetricSpec(
            title: '监控中仓库',
            value: '36',
            delta: '+3',
            subtitle: '本周新增',
            icon: Icons.visibility_outlined,
          ),
          const HomeMetricSpec(
            title: '今日告警',
            value: '12',
            delta: '-2',
            subtitle: '对比昨日',
            icon: Icons.notifications_active_outlined,
            accent: AppColors.warning,
          ),
        ];
      case HomeLegacyTab.growth:
        return [
          const HomeMetricSpec(
            title: '7 日新增 Star',
            value: '892',
            delta: '+24.3%',
            subtitle: '对比上周',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const HomeMetricSpec(
            title: '增长率 Top 1',
            value: '62.4%',
            delta: '+12.8%',
            subtitle: 'llama.cpp',
            icon: Icons.trending_up_rounded,
          ),
          const HomeMetricSpec(
            title: '增长中仓库',
            value: '1,284',
            delta: '+96',
            subtitle: '过去 24h',
            icon: Icons.show_chart_rounded,
          ),
          const HomeMetricSpec(
            title: '回落预警',
            value: '5',
            delta: '+1',
            subtitle: '需关注',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
        ];
      case HomeLegacyTab.health:
        return [
          const HomeMetricSpec(
            title: '活跃贡献者',
            value: '8.2K',
            delta: '+4.1%',
            subtitle: '过去 30 天',
            icon: Icons.people_rounded,
          ),
          const HomeMetricSpec(
            title: '平均 Issue 响应',
            value: '6.4h',
            delta: '-0.8h',
            subtitle: '更快',
            icon: Icons.support_agent_rounded,
            accent: AppColors.success,
          ),
          const HomeMetricSpec(
            title: '最近提交',
            value: '3 天内',
            delta: '92%',
            subtitle: '持续维护',
            icon: Icons.commit_rounded,
          ),
          const HomeMetricSpec(
            title: '弃用风险',
            value: '7',
            delta: '-2',
            subtitle: '90 天未更新',
            icon: Icons.report_problem_outlined,
            accent: AppColors.danger,
          ),
        ];
      case HomeLegacyTab.starred:
        return [
          HomeMetricSpec(
            title: '收藏仓库',
            value: '24',
            delta: '+3',
            subtitle: '本周新增',
            icon: Icons.bookmark_rounded,
            accent: primary,
          ),
          const HomeMetricSpec(
            title: '收藏总 Star',
            value: '128K',
            delta: '+1,840',
            subtitle: '本周增长',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const HomeMetricSpec(
            title: '近 7 日更新',
            value: '11',
            delta: '+4',
            subtitle: '有动态',
            icon: Icons.notifications_active_outlined,
          ),
          const HomeMetricSpec(
            title: '待跟进',
            value: '6',
            delta: '-1',
            subtitle: '未读',
            icon: Icons.bookmark_outline,
            accent: AppColors.warning,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMedium = Breakpoints.isMedium(context);
    final specs = _specsFor(tab, Theme.of(context).colorScheme.primary);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: GridView.count(
        key: ValueKey<HomeLegacyTab>(tab),
        crossAxisCount: isMedium ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: isMedium ? 1.7 : 1.6,
        children: [
          for (final s in specs)
            MetricCard(
              title: s.title,
              value: s.value,
              delta: s.delta,
              subtitle: s.subtitle,
              icon: s.icon,
              accent: s.accent,
            ),
        ],
      ),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.window,
    required this.onChanged,
    required this.tab,
  });
  final int window;
  final ValueChanged<int> onChanged;
  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context) {
    final series = homeSeriesForWindow(
      window,
      tab,
      Theme.of(context).colorScheme.primary,
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
