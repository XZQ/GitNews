import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/star_trend_chart.dart';

/*
*Home 旧版 mobile / tablet 共用的页内分类(归档实现)。
*/
enum HomeLegacyTab {
  trending,
  growth,
  health,
  starred;

  String label(AppLocalizations l10n) {
    switch (this) {
      case HomeLegacyTab.trending:
        return l10n.tr('home.tab.trending');
      case HomeLegacyTab.growth:
        return l10n.tr('home.tab.growth');
      case HomeLegacyTab.health:
        return l10n.tr('home.tab.health');
      case HomeLegacyTab.starred:
        return l10n.tr('home.tab.starred');
    }
  }

  IconData get activeIcon {
    switch (this) {
      case HomeLegacyTab.trending:
        return Icons.trending_up_rounded;
      case HomeLegacyTab.growth:
        return Icons.star_rounded;
      case HomeLegacyTab.health:
        return Icons.favorite_rounded;
      case HomeLegacyTab.starred:
        return Icons.bookmark_rounded;
    }
  }

  IconData get idleIcon {
    switch (this) {
      case HomeLegacyTab.trending:
        return Icons.trending_up_outlined;
      case HomeLegacyTab.growth:
        return Icons.star_outline_rounded;
      case HomeLegacyTab.health:
        return Icons.favorite_outline_rounded;
      case HomeLegacyTab.starred:
        return Icons.bookmark_outline_rounded;
    }
  }
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

String homeChartTitle(AppLocalizations l10n, HomeLegacyTab tab) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return l10n.tr('home.chart.trending');
    case HomeLegacyTab.growth:
      return l10n.tr('home.chart.growth');
    case HomeLegacyTab.health:
      return l10n.tr('home.chart.health');
    case HomeLegacyTab.starred:
      return l10n.tr('home.chart.starred');
  }
}

String homeChartSubtitle(AppLocalizations l10n, HomeLegacyTab tab, String window) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return l10n.tr('home.chart.subtitle.trending').replaceAll('{window}', window);
    case HomeLegacyTab.growth:
      return l10n.tr('home.chart.subtitle.growth').replaceAll('{window}', window);
    case HomeLegacyTab.health:
      return l10n.tr('home.chart.subtitle.health').replaceAll('{window}', window);
    case HomeLegacyTab.starred:
      return l10n.tr('home.chart.subtitle.starred').replaceAll('{window}', window);
  }
}

List<HomeLegendItem> homeChartLegends(AppLocalizations l10n, HomeLegacyTab tab, Color primary) {
  switch (tab) {
    case HomeLegacyTab.trending:
      return [HomeLegendItem(color: primary, label: l10n.tr('home.chart.legend.this_week')), HomeLegendItem(color: AppColors.info, label: l10n.tr('home.chart.legend.last_week'))];
    case HomeLegacyTab.growth:
      return [HomeLegendItem(color: AppColors.success, label: l10n.tr('home.chart.legend.growth_rate')), HomeLegendItem(color: AppColors.warning, label: l10n.tr('home.chart.legend.baseline'))];
    case HomeLegacyTab.health:
      return [HomeLegendItem(color: primary, label: l10n.tr('home.chart.legend.commits')), HomeLegendItem(color: AppColors.success, label: l10n.tr('home.chart.legend.contributors'))];
    case HomeLegacyTab.starred:
      return [HomeLegendItem(color: AppColors.starGold, label: l10n.tr('home.chart.legend.starred')), HomeLegendItem(color: AppColors.info, label: l10n.tr('home.chart.legend.avg'))];
  }
}

List<ChartSeries> homeSeriesForWindow(
  int days,
  HomeLegacyTab tab,
  Color primary, {
  List<double>? primaryTrend,
  List<double>? secondaryTrend,
}) {
  final dynamicPrimary = _windowedTrend(primaryTrend, days);
  final dynamicSecondary = _windowedTrend(secondaryTrend, days);
  if (tab == HomeLegacyTab.trending && dynamicPrimary.isNotEmpty) {
    return [ChartSeries(values: dynamicPrimary, color: primary), ChartSeries(values: dynamicSecondary.isEmpty ? dynamicPrimary : dynamicSecondary, color: AppColors.info)];
  }

  final baseA = 38000 + days * 110;
  final deltaA = 3500 + days * 110;
  final baseB = 36000 + days * 95;
  final deltaB = 2700 + days * 95;
  switch (tab) {
    case HomeLegacyTab.trending:
      return [
        ChartSeries(values: DemoData.generateStarTrend(baseA, deltaA, count: days), color: primary),
        ChartSeries(values: DemoData.generateStarTrend(baseB, deltaB, count: days), color: AppColors.info)
      ];
    case HomeLegacyTab.growth:
      return [
        ChartSeries(values: DemoData.generateStarTrend(baseA, deltaA ~/ 2, count: days), color: AppColors.success),
        ChartSeries(values: DemoData.generateStarTrend(baseB, deltaB, count: days), color: AppColors.warning)
      ];
    case HomeLegacyTab.health:
      return [
        ChartSeries(values: DemoData.generateStarTrend(baseA, deltaA, count: days), color: primary),
        ChartSeries(values: DemoData.generateStarTrend(baseB, deltaB ~/ 2, count: days), color: AppColors.success)
      ];
    case HomeLegacyTab.starred:
      return [
        ChartSeries(values: DemoData.generateStarTrend(baseA + 8000, deltaA, count: days), color: AppColors.starGold),
        ChartSeries(values: DemoData.generateStarTrend(baseB + 6000, deltaB, count: days), color: AppColors.info)
      ];
  }
}

List<double> _windowedTrend(List<double>? values, int days) {
  if (values == null || values.isEmpty) {
    return const [];
  }
  if (values.length <= days) {
    return values;
  }
  return values.sublist(values.length - days);
}
