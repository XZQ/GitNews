import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 顶部四宫格核心指标。
class TrendingHeroMetrics extends StatelessWidget {
  const TrendingHeroMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: TrendingMetric(
            value: '42.8K',
            label: 'Star 增长总量',
            delta: '+7.2%',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: TrendingMetric(
            value: '1.20K',
            label: '周活跃仓库',
            delta: '+12.4%',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: TrendingMetric(
            value: '10.6K',
            label: '新增 Fork',
            delta: '+5.1%',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: TrendingMetric(
            value: '623',
            label: '热门话题',
            delta: '+3.4%',
          ),
        ),
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
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          delta,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 时间窗切换:today/week/month。
class TrendingWindowSegmented extends StatelessWidget {
  const TrendingWindowSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'today', label: Text('今日')),
        ButtonSegment(value: 'week', label: Text('本周')),
        ButtonSegment(value: 'month', label: Text('本月')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// 通用语言筛选 PopupMenu。
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
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem(value: o, child: Text(optionLabel(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: 14),
            const SizedBox(width: 4),
            Text(optionLabel(value), style: AppTypography.labelMedium),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}
