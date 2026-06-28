// Home 在 compact / medium 断点下的旧实现(归档)。
//
// Expanded(>=1024)由 `DevIntelDesktopPage` 接管,本文件仅保留 mobile /
// tablet 两个分支:`HomeMobileBody` / `HomeTabletBody`,以及它们依赖的
// `_OverviewMetricsRow` / `_DesktopMainLayout` / `_ChartCard` /
// `_WindowSegment` / `_TodayStack` / `_TodayCard`。

import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../widgets/home_alerts_panel.dart';
import '../widgets/home_topics_panel.dart';

class HomeMobileBody extends StatelessWidget {
  const HomeMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        _MobileHero(),
        SizedBox(height: AppSpacing.lg),
        HomeAlertsPanel(showHeader: true, maxItems: 5),
        SizedBox(height: AppSpacing.lg),
        HomeTopicsPanel(),
      ],
    );
  }
}

class _MobileHero extends StatefulWidget {
  const _MobileHero();

  @override
  State<_MobileHero> createState() => _MobileHeroState();
}

class _MobileHeroState extends State<_MobileHero> {
  int _window = 7;

  @override
  Widget build(BuildContext context) {
    final series = _seriesForWindow(
      _window,
      _HomeTab.trending,
      Theme.of(context).colorScheme.primary,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Star 增长趋势',
                  style: AppTypography.titleLarge,
                ),
              ),
              _WindowSegment(
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '最近 $_window 天 · 与上周对比',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(series: series, height: 200),
        ],
      ),
    );
  }
}

class HomeTabletBody extends StatefulWidget {
  const HomeTabletBody({super.key});

  @override
  State<HomeTabletBody> createState() => _HomeTabletBodyState();
}

class _HomeTabletBodyState extends State<HomeTabletBody> {
  int _chartWindow = 7;
  final _HomeTab _tab = _HomeTab.trending;

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

enum _HomeTab {
  trending('趋势榜', Icons.trending_up_rounded, Icons.trending_up_outlined),
  growth('增长榜', Icons.star_rounded, Icons.star_outline_rounded),
  health('健康榜', Icons.favorite_rounded, Icons.favorite_outline_rounded),
  starred('收藏趋势榜', Icons.bookmark_rounded, Icons.bookmark_outline_rounded);

  const _HomeTab(this.label, this.activeIcon, this.idleIcon);

  final String label;
  final IconData activeIcon;
  final IconData idleIcon;
}

class _OverviewMetricsRow extends StatelessWidget {
  const _OverviewMetricsRow({required this.tab});

  final _HomeTab tab;

  List<_MetricSpec> _specsFor(_HomeTab tab, Color primary) {
    switch (tab) {
      case _HomeTab.trending:
        return [
          const _MetricSpec(
            title: '今日新增 Star',
            value: '128',
            delta: '+18.5%',
            subtitle: '对比昨日',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const _MetricSpec(
            title: 'Star 增长榜仓库',
            value: '42.8K',
            delta: '+7.2%',
            subtitle: '趋势榜首',
            icon: Icons.trending_up_rounded,
          ),
          const _MetricSpec(
            title: '监控中仓库',
            value: '36',
            delta: '+3',
            subtitle: '本周新增',
            icon: Icons.visibility_outlined,
          ),
          const _MetricSpec(
            title: '今日告警',
            value: '12',
            delta: '-2',
            subtitle: '对比昨日',
            icon: Icons.notifications_active_outlined,
            accent: AppColors.warning,
          ),
        ];
      case _HomeTab.growth:
        return [
          const _MetricSpec(
            title: '7 日新增 Star',
            value: '892',
            delta: '+24.3%',
            subtitle: '对比上周',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const _MetricSpec(
            title: '增长率 Top 1',
            value: '62.4%',
            delta: '+12.8%',
            subtitle: 'llama.cpp',
            icon: Icons.trending_up_rounded,
          ),
          const _MetricSpec(
            title: '增长中仓库',
            value: '1,284',
            delta: '+96',
            subtitle: '过去 24h',
            icon: Icons.show_chart_rounded,
          ),
          const _MetricSpec(
            title: '回落预警',
            value: '5',
            delta: '+1',
            subtitle: '需关注',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
          ),
        ];
      case _HomeTab.health:
        return [
          const _MetricSpec(
            title: '活跃贡献者',
            value: '8.2K',
            delta: '+4.1%',
            subtitle: '过去 30 天',
            icon: Icons.people_rounded,
          ),
          const _MetricSpec(
            title: '平均 Issue 响应',
            value: '6.4h',
            delta: '-0.8h',
            subtitle: '更快',
            icon: Icons.support_agent_rounded,
            accent: AppColors.success,
          ),
          const _MetricSpec(
            title: '最近提交',
            value: '3 天内',
            delta: '92%',
            subtitle: '持续维护',
            icon: Icons.commit_rounded,
          ),
          const _MetricSpec(
            title: '弃用风险',
            value: '7',
            delta: '-2',
            subtitle: '90 天未更新',
            icon: Icons.report_problem_outlined,
            accent: AppColors.danger,
          ),
        ];
      case _HomeTab.starred:
        return [
          _MetricSpec(
            title: '收藏仓库',
            value: '24',
            delta: '+3',
            subtitle: '本周新增',
            icon: Icons.bookmark_rounded,
            accent: primary,
          ),
          const _MetricSpec(
            title: '收藏总 Star',
            value: '128K',
            delta: '+1,840',
            subtitle: '本周增长',
            icon: Icons.star_rounded,
            accent: AppColors.starGold,
          ),
          const _MetricSpec(
            title: '近 7 日更新',
            value: '11',
            delta: '+4',
            subtitle: '有动态',
            icon: Icons.notifications_active_outlined,
          ),
          const _MetricSpec(
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
        key: ValueKey<_HomeTab>(tab),
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

class _MetricSpec {
  const _MetricSpec({
    required this.title,
    required this.value,
    required this.delta,
    required this.subtitle,
    required this.icon,
    this.accent,
  });
  final String title;
  final String value;
  final String delta;
  final String subtitle;
  final IconData icon;
  final Color? accent;
}

class _DesktopMainLayout extends StatelessWidget {
  const _DesktopMainLayout({
    required this.chartWindow,
    required this.onChartWindowChanged,
    required this.tab,
  });

  final int chartWindow;
  final ValueChanged<int> onChartWindowChanged;
  final _HomeTab tab;

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
          Expanded(flex: 4, child: _TodayStack(tab: tab)),
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
  final _HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final series =
        _seriesForWindow(window, tab, Theme.of(context).colorScheme.primary);
    final windowLabel = '近 $window 天';
    final title = _chartTitle(tab);
    final subtitle = _chartSubtitle(tab, windowLabel);
    final legends = _chartLegends(tab, Theme.of(context).colorScheme.primary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: title,
                  subtitle: subtitle,
                ),
              ),
              _WindowSegment(value: window, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < legends.length; i++) ...[
                _LegendDot(color: legends[i].color, label: legends[i].label),
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

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

String _chartTitle(_HomeTab tab) {
  switch (tab) {
    case _HomeTab.trending:
      return 'Star 增长趋势';
    case _HomeTab.growth:
      return '增长率曲线';
    case _HomeTab.health:
      return '活跃度曲线';
    case _HomeTab.starred:
      return '收藏仓库 Star 趋势';
  }
}

String _chartSubtitle(_HomeTab tab, String window) {
  switch (tab) {
    case _HomeTab.trending:
      return '$window · 与上周对比';
    case _HomeTab.growth:
      return '$window · 增长率排名变动';
    case _HomeTab.health:
      return '$window · 提交与活跃贡献者';
    case _HomeTab.starred:
      return '$window · 收藏仓库总体增长';
  }
}

List<_LegendItem> _chartLegends(_HomeTab tab, Color primary) {
  switch (tab) {
    case _HomeTab.trending:
      return [
        _LegendItem(color: primary, label: '本周'),
        const _LegendItem(color: AppColors.info, label: '上周'),
      ];
    case _HomeTab.growth:
      return [
        const _LegendItem(color: AppColors.success, label: '增长率'),
        const _LegendItem(color: AppColors.warning, label: '基线'),
      ];
    case _HomeTab.health:
      return [
        _LegendItem(color: primary, label: '提交数'),
        const _LegendItem(color: AppColors.success, label: '贡献者'),
      ];
    case _HomeTab.starred:
      return [
        const _LegendItem(color: AppColors.starGold, label: '收藏 Star'),
        const _LegendItem(color: AppColors.info, label: '全网平均'),
      ];
  }
}

class _WindowSegment extends StatelessWidget {
  const _WindowSegment({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7天')),
        ButtonSegment(value: 14, label: Text('14天')),
        ButtonSegment(value: 30, label: Text('30天')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _TodayStack extends StatelessWidget {
  const _TodayStack({required this.tab});
  final _HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cards = switch (tab) {
      _HomeTab.trending => [
          const _TodayCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            label: '今日 Star 增长',
            value: '4,231',
            delta: '+18.5%',
            items: 3,
          ),
          const _TodayCard(
            icon: Icons.forum_outlined,
            iconColor: AppColors.info,
            label: '今日讨论',
            value: '1,827',
            delta: '+9.2%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.commit_rounded,
            iconColor: AppColors.success,
            label: '今日 Commits',
            value: '12,940',
            delta: '+4.1%',
            items: 4,
          ),
        ],
      _HomeTab.growth => [
          const _TodayCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            label: '最快增长仓库',
            value: '+62.4%',
            delta: 'llama.cpp',
            items: 1,
          ),
          _TodayCard(
            icon: Icons.show_chart_rounded,
            iconColor: primary,
            label: '增长中仓库',
            value: '1,284',
            delta: '+96',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            label: '增速回落',
            value: '5',
            delta: '需关注',
            items: 3,
          ),
        ],
      _HomeTab.health => [
          _TodayCard(
            icon: Icons.people_rounded,
            iconColor: primary,
            label: '活跃贡献者',
            value: '8.2K',
            delta: '+4.1%',
            items: 1,
          ),
          const _TodayCard(
            icon: Icons.commit_rounded,
            iconColor: AppColors.success,
            label: '今日 Commits',
            value: '12,940',
            delta: '+4.1%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.support_agent_rounded,
            iconColor: AppColors.info,
            label: 'Issue 响应中位',
            value: '6.4h',
            delta: '-0.8h',
            items: 3,
          ),
        ],
      _HomeTab.starred => [
          _TodayCard(
            icon: Icons.bookmark_rounded,
            iconColor: primary,
            label: '收藏仓库',
            value: '24',
            delta: '+3',
            items: 1,
          ),
          const _TodayCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            label: '近 7 日 Star',
            value: '1,840',
            delta: '+12.8%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: '待跟进',
            value: '6',
            delta: '-1',
            items: 3,
          ),
        ],
    };
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.delta,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String delta;
  final int items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      delta,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$items',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<ChartSeries> _seriesForWindow(int days, _HomeTab tab, Color primary) {
  final baseA = 38000 + days * 110;
  final deltaA = 3500 + days * 110;
  final baseB = 36000 + days * 95;
  final deltaB = 2700 + days * 95;
  switch (tab) {
    case _HomeTab.trending:
      return [
        ChartSeries(
          values: DemoData.generateStarTrend(baseA, deltaA, count: days),
          color: primary,
        ),
        ChartSeries(
          values: DemoData.generateStarTrend(baseB, deltaB, count: days),
          color: AppColors.info,
        ),
      ];
    case _HomeTab.growth:
      return [
        ChartSeries(
          values: DemoData.generateStarTrend(baseA, deltaA ~/ 2, count: days),
          color: AppColors.success,
        ),
        ChartSeries(
          values: DemoData.generateStarTrend(baseB, deltaB, count: days),
          color: AppColors.warning,
        ),
      ];
    case _HomeTab.health:
      return [
        ChartSeries(
          values: DemoData.generateStarTrend(baseA, deltaA, count: days),
          color: primary,
        ),
        ChartSeries(
          values: DemoData.generateStarTrend(baseB, deltaB ~/ 2, count: days),
          color: AppColors.success,
        ),
      ];
    case _HomeTab.starred:
      return [
        ChartSeries(
          values: DemoData.generateStarTrend(baseA + 8000, deltaA, count: days),
          color: AppColors.starGold,
        ),
        ChartSeries(
          values: DemoData.generateStarTrend(baseB + 6000, deltaB, count: days),
          color: AppColors.info,
        ),
      ];
  }
}
