import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/* 
*顶部四宫格核心指标。
*/
class TrendingHeroMetrics extends StatelessWidget {
  const TrendingHeroMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: TrendingMetric(value: '42.8K', label: l10n.tr('trending.metric.total_stars'), delta: '+7.2%')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: TrendingMetric(value: '1.20K', label: l10n.tr('trending.metric.active_repos'), delta: '+12.4%')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: TrendingMetric(value: '10.6K', label: l10n.tr('trending.metric.new_forks'), delta: '+5.1%')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: TrendingMetric(value: '623', label: l10n.tr('trending.metric.hot_topics'), delta: '+3.4%'))
      ],
    );
  }
}

class TrendingMetric extends StatelessWidget {
  const TrendingMetric({
    super.key,
    required this.value,
    required this.label,
    required this.delta,
  });

  final String value;
  final String label;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xxs),
        Text(delta, style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))
      ],
    );
  }
}

/*
*时间窗切换:today/week/month。
*
*[dense] 供移动端与区块标题同行摆放:收紧内边距和最小点击尺寸,
*  否则默认 M3 尺寸会把同行的标题挤到只剩两三个字。
*/
class TrendingWindowSegmented extends StatelessWidget {
  const TrendingWindowSegmented({super.key, required this.value, required this.onChanged, this.dense = false});

  final String value;
  final ValueChanged<String> onChanged;

  // 紧凑密度开关,默认关闭以保持桌面端既有尺寸。
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'today', label: Text(l10n.tr('trending.window.today'))),
        ButtonSegment(value: 'week', label: Text(l10n.tr('trending.window.week'))),
        ButtonSegment(value: 'month', label: Text(l10n.tr('trending.window.month')))
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: dense
          ? SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2, vertical: AppSpacing.xs),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: AppTypography.labelSmall,
            )
          : null,
    );
  }
}

/* 
*通用语言筛选 PopupMenu。
*/
class TrendingPopupMenu extends StatelessWidget {
  const TrendingPopupMenu({
    super.key,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  final String value;
  final List<String> options;
  final String Function(String) optionLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => [for (final o in options) PopupMenuItem(value: o, child: Text(optionLabel(o)))],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs2),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: AppSpacing.md2),
            const SizedBox(width: AppSpacing.xs),
            Text(optionLabel(value), style: AppTypography.labelMedium),
            const Icon(Icons.arrow_drop_down, size: AppSpacing.lg)
          ],
        ),
      ),
    );
  }
}
