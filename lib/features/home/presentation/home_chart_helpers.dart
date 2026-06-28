import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/star_trend_chart.dart';

/// Home 旧版 mobile / tablet 共用的页内分类(归档实现)。
enum HomeLegacyTab {
  trending('趋势榜', Icons.trending_up_rounded, Icons.trending_up_outlined),
  growth('增长榜', Icons.star_rounded, Icons.star_outline_rounded),
  health('健康榜', Icons.favorite_rounded, Icons.favorite_outline_rounded),
  starred('收藏趋势榜', Icons.bookmark_rounded, Icons.bookmark_outline_rounded);

  const HomeLegacyTab(this.label, this.activeIcon, this.idleIcon);

  final String label;
  final IconData activeIcon;
  final IconData idleIcon;
}

class HomeMetricSpec {
  const HomeMetricSpec({
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

class HomeLegendItem {
  const HomeLegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

String homeChartTitle(HomeLegacyTab tab) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return 'Star 增长趋势';
    case HomeLegacyTab.growth:
      return '增长率曲线';
    case HomeLegacyTab.health:
      return '活跃度曲线';
    case HomeLegacyTab.starred:
      return '收藏仓库 Star 趋势';
  }
}

String homeChartSubtitle(HomeLegacyTab tab, String window) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return '$window · 与上周对比';
    case HomeLegacyTab.growth:
      return '$window · 增长率排名变动';
    case HomeLegacyTab.health:
      return '$window · 提交与活跃贡献者';
    case HomeLegacyTab.starred:
      return '$window · 收藏仓库总体增长';
  }
}

List<HomeLegendItem> homeChartLegends(HomeLegacyTab tab, Color primary) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return [
        HomeLegendItem(color: primary, label: '本周'),
        const HomeLegendItem(color: AppColors.info, label: '上周'),
      ];
    case HomeLegacyTab.growth:
      return [
        const HomeLegendItem(color: AppColors.success, label: '增长率'),
        const HomeLegendItem(color: AppColors.warning, label: '基线'),
      ];
    case HomeLegacyTab.health:
      return [
        HomeLegendItem(color: primary, label: '提交数'),
        const HomeLegendItem(color: AppColors.success, label: '贡献者'),
      ];
    case HomeLegacyTab.starred:
      return [
        const HomeLegendItem(color: AppColors.starGold, label: '收藏 Star'),
        const HomeLegendItem(color: AppColors.info, label: '全网平均'),
      ];
  }
}

List<ChartSeries> homeSeriesForWindow(
  int days,
  HomeLegacyTab tab,
  Color primary,
) {
  final baseA = 38000 + days * 110;
  final deltaA = 3500 + days * 110;
  final baseB = 36000 + days * 95;
  final deltaB = 2700 + days * 95;
  switch (tab) {
    case HomeLegacyTab.trending:
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
    case HomeLegacyTab.growth:
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
    case HomeLegacyTab.health:
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
    case HomeLegacyTab.starred:
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

/// 7 / 14 / 30 天窗口切换。
class ChartWindowSegmented extends StatelessWidget {
  const ChartWindowSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

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

class HomeLegendDot extends StatelessWidget {
  const HomeLegendDot({required this.color, required this.label, super.key});

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
