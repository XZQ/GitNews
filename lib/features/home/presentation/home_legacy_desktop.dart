// 旧的桌面端 home 实现(归档)。
//
// 在 Expanded 断点下,`HomePage` 会直接返回新的 `DevIntelDesktopPage`,
// 因此本文件中的 `_HomeDesktopBody` 与其依赖类已经不会被实例化,
// 但仍需保留(作为历史实现 + 兜底)。
//
// Medium 断点(600~1024)走 `HomeTabletBody`,而 `HomeTabletBody` 内部
// 调用了 `_OverviewMetricsRow` / `_DesktopMainLayout` / `_ChartCard` /
// `_TodayStack` / `_RepoTableCard` / `_LanguageDistributionCard` /
// `_WindowSegment` —— 这些类已经从原 `home_page.dart` 整体迁出至本文件,
// 以避免 `home_page.dart` 超过 300 行。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
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

/// 仓库表格列类型:用枚举而非本地化字符串做 dispatch。
enum _ColumnType { totalStar, today, growthRate, fork }

class _HomeDesktopBody extends StatefulWidget {
  const _HomeDesktopBody();

  @override
  State<_HomeDesktopBody> createState() => _HomeDesktopBodyState();
}

class _HomeDesktopBodyState extends State<_HomeDesktopBody> {
  _HomeTab _tab = _HomeTab.trending;
  int _chartWindow = 7;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DesktopTopBar(),
        _DesktopTabRow(
          active: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        Expanded(
          child: CenteredContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _OverviewMetricsRow(tab: _tab),
                const SizedBox(height: AppSpacing.lg),
                _DesktopMainLayout(
                  chartWindow: _chartWindow,
                  onChartWindowChanged: (v) => setState(() => _chartWindow = v),
                  tab: _tab,
                ),
                const SizedBox(height: AppSpacing.lg),
                _DesktopBottomRow(tab: _tab),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _SearchField(
              hint: '搜索仓库、开发者、话题...',
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                context.go('/trending/repos');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _IconAction(
            icon: Icons.refresh_rounded,
            tooltip: '刷新',
            onTap: () {},
          ),
          _IconAction(
            icon: Icons.notifications_none_rounded,
            tooltip: '告警',
            onTap: () => context.go('/monitor'),
          ),
          _IconAction(
            icon: Icons.settings_outlined,
            tooltip: '偏好设置',
            onTap: () => context.go('/profile'),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _Avatar(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onSubmitted});
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: TextField(
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          ),
          filled: true,
          fillColor: colors.surfaceContainerLow,
        ),
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconBtn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                _hovered ? colors.surfaceContainerHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(widget.icon, size: 18, color: colors.onSurfaceVariant),
        ),
      ),
    );
    return widget.tooltip == null
        ? iconBtn
        : Tooltip(message: widget.tooltip!, child: iconBtn);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/profile'),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.primary],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _DesktopTabRow extends StatelessWidget {
  const _DesktopTabRow({required this.active, required this.onChanged});

  final _HomeTab active;
  final ValueChanged<_HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final t in _HomeTab.values) ...[
            _TabChip(
              tab: t,
              active: t == active,
              onTap: () => onChanged(t),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Spacer(),
          const _DateRangeChip(text: '2025-11-08 ~ 2026-06-23'),
        ],
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final _HomeTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = widget.active
        ? colors.primary.withValues(alpha: 0.14)
        : (_hovered ? colors.surfaceContainerHighest : Colors.transparent);
    final fg = widget.active ? colors.primary : colors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active ? widget.tab.activeIcon : widget.tab.idleIcon,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                widget.tab.label,
                style: AppTypography.labelLarge.copyWith(
                  color: fg,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
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

class _DesktopBottomRow extends StatelessWidget {
  const _DesktopBottomRow({required this.tab});
  final _HomeTab tab;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _RepoTableCard(tab: tab)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 5, child: _LanguageDistributionCard(tab: tab)),
      ],
    );
  }
}

class _RepoTableCard extends StatelessWidget {
  const _RepoTableCard({required this.tab});
  final _HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repos = _reposFor(tab);
    final header = _tableHeader(tab);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SectionHeader(
              title: header.title,
              subtitle: header.subtitle,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    '仓库',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '语言',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Text(
                    _colTypeLabel(header.col1),
                    textAlign: TextAlign.right,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    _colTypeLabel(header.col2),
                    textAlign: TextAlign.right,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _colTypeLabel(header.col3),
                    textAlign: TextAlign.right,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < repos.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _RepoRow(
              repo: repos[i],
              col1Type: header.col1,
              col2Type: header.col2,
              col3Type: header.col3,
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(repos[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DemoRepo> _reposFor(_HomeTab tab) {
    final all = <DemoRepo>[...DemoData.trending, ...DemoData.recent];
    switch (tab) {
      case _HomeTab.trending:
        return all.take(6).toList();
      case _HomeTab.growth:
        return ([...all]..sort((a, b) => b.starDelta.compareTo(a.starDelta)))
            .take(6)
            .toList();
      case _HomeTab.health:
        return ([...all]..sort((a, b) => b.forkCount.compareTo(a.forkCount)))
            .take(6)
            .toList();
      case _HomeTab.starred:
        return ([...all]..sort((a, b) => b.starCount.compareTo(a.starCount)))
            .take(6)
            .toList();
    }
  }

  _TableHeader _tableHeader(_HomeTab tab) {
    switch (tab) {
      case _HomeTab.trending:
        return const _TableHeader(
          title: '趋势增长榜',
          subtitle: '今日 Star 增长 Top 6 · 按增速排序',
          col1: _ColumnType.totalStar,
          col2: _ColumnType.today,
          col3: _ColumnType.fork,
        );
      case _HomeTab.growth:
        return const _TableHeader(
          title: '增长率榜',
          subtitle: '近 7 日增长率排序 · Top 6',
          col1: _ColumnType.totalStar,
          col2: _ColumnType.growthRate,
          col3: _ColumnType.fork,
        );
      case _HomeTab.health:
        return const _TableHeader(
          title: '活跃仓库榜',
          subtitle: '按 Fork 与维护活跃度排序',
          col1: _ColumnType.totalStar,
          col2: _ColumnType.fork,
          col3: _ColumnType.today,
        );
      case _HomeTab.starred:
        return const _TableHeader(
          title: '收藏候选榜',
          subtitle: '按总 Star 排序 · 高质量仓库',
          col1: _ColumnType.totalStar,
          col2: _ColumnType.today,
          col3: _ColumnType.fork,
        );
    }
  }
}

class _TableHeader {
  const _TableHeader({
    required this.title,
    required this.subtitle,
    required this.col1,
    required this.col2,
    required this.col3,
  });
  final String title;
  final String subtitle;
  final _ColumnType col1;
  final _ColumnType col2;
  final _ColumnType col3;
}

String _colTypeLabel(_ColumnType type) {
  switch (type) {
    case _ColumnType.totalStar:
      return '总 Star';
    case _ColumnType.today:
      return '今日';
    case _ColumnType.growthRate:
      return '增长率';
    case _ColumnType.fork:
      return 'Fork';
  }
}

class _RepoRow extends StatelessWidget {
  const _RepoRow({
    required this.repo,
    required this.onTap,
    required this.col1Type,
    required this.col2Type,
    required this.col3Type,
  });
  final DemoRepo repo;
  final VoidCallback onTap;
  final _ColumnType col1Type;
  final _ColumnType col2Type;
  final _ColumnType col3Type;

  double get _growthPct =>
      repo.starCount == 0 ? 0.0 : (repo.starDelta / repo.starCount * 100);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(repo.color).withValues(alpha: 0.18),
                    child: Text(
                      repo.fullName[0].toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: Color(repo.color),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.fullName,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          repo.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                repo.language,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                _colValue(col1Type),
                textAlign: TextAlign.right,
                style: AppTypography.titleSmall,
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                _colDelta(col2Type),
                textAlign: TextAlign.right,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                _colTertiary(col3Type),
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _colValue(_ColumnType type) {
    switch (type) {
      case _ColumnType.totalStar:
        return _compact(repo.starCount);
      case _ColumnType.growthRate:
        return '+${_growthPct.toStringAsFixed(1)}%';
      case _ColumnType.fork:
        return _compact(repo.forkCount);
      case _ColumnType.today:
        return _compact(repo.starCount);
    }
  }

  String _colDelta(_ColumnType type) {
    switch (type) {
      case _ColumnType.today:
        return '+${_compact(repo.starDelta)}';
      case _ColumnType.growthRate:
        return '+${_growthPct.toStringAsFixed(1)}%';
      case _ColumnType.fork:
        return _compact(repo.forkCount);
      case _ColumnType.totalStar:
        return '+${_compact(repo.starDelta)}';
    }
  }

  String _colTertiary(_ColumnType type) {
    switch (type) {
      case _ColumnType.fork:
        return _compact(repo.forkCount);
      case _ColumnType.today:
        return '+${_compact(repo.starDelta)}';
      case _ColumnType.totalStar:
      case _ColumnType.growthRate:
        return _compact(repo.forkCount);
    }
  }

  String _compact(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _LanguageDistributionCard extends StatelessWidget {
  const _LanguageDistributionCard({required this.tab});
  final _HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final data = _languageDataFor(tab);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: _langTitle(tab),
            subtitle: _langSubtitle(tab),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final l in data)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LangBar(
                name: l.name,
                percent: l.percent,
                color: Color(l.color),
              ),
            ),
        ],
      ),
    );
  }

  String _langTitle(_HomeTab tab) {
    switch (tab) {
      case _HomeTab.trending:
        return '语言分布';
      case _HomeTab.growth:
        return '增长率领先的语言';
      case _HomeTab.health:
        return '活跃度贡献的语言';
      case _HomeTab.starred:
        return '高 Star 收藏的语言';
    }
  }

  String _langSubtitle(_HomeTab tab) {
    switch (tab) {
      case _HomeTab.trending:
        return '当前榜单仓库的编程语言占比';
      case _HomeTab.growth:
        return '近 7 日增长率排名前列的语言';
      case _HomeTab.health:
        return '贡献最多维护活跃度的语言';
      case _HomeTab.starred:
        return '你收藏仓库的高 Star 语言分布';
    }
  }

  List<DemoLanguage> _languageDataFor(_HomeTab tab) {
    final all = [...DemoData.languages];
    switch (tab) {
      case _HomeTab.trending:
        return all.take(6).toList();
      case _HomeTab.growth:
        return ([...all]..sort((a, b) => b.delta.compareTo(a.delta)))
            .take(6)
            .toList();
      case _HomeTab.health:
        return ([...all]..sort((a, b) => b.percent.compareTo(a.percent)))
            .take(6)
            .toList();
      case _HomeTab.starred:
        return all.reversed.take(6).toList();
    }
  }
}

class _LangBar extends StatelessWidget {
  const _LangBar({
    required this.name,
    required this.percent,
    required this.color,
  });
  final String name;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            name,
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurface,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: colors.surfaceContainerHighest,
                ),
                FractionallySizedBox(
                  widthFactor: (percent / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 48,
          child: Text(
            '${percent.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
