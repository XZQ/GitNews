import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities.dart';

/* 语言增长率排行(水平条形)。 */
class LanguageGrowthBars extends StatelessWidget {
  const LanguageGrowthBars({required this.languages, super.key});

  final List<LanguageEntity> languages;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();
    final maxV = languages
        .fold<double>(
          0,
          (m, l) => l.delta.abs() > m ? l.delta.abs() : m,
        )
        .clamp(1.0, double.infinity);
    return Column(
      children: [
        for (final l in languages) ...[
          _Bar(
            name: l.name,
            value: l.delta,
            maxValue: maxV,
            color: Color(l.accentArgb),
          ),
          const SizedBox(height: AppSpacing.sm2),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.name,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String name;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(name, style: AppTypography.labelMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Stack(
              children: [
                Container(
                  height: 16,
                  color: colors.surfaceContainerHighest,
                ),
                FractionallySizedBox(
                  widthFactor: (value / maxValue).clamp(0.0, 1.0),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          child: Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: value >= 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/* 语言占比单行(色块 + 名称 + 百分比 + delta)。 */
class LanguageDistributionRow extends StatelessWidget {
  const LanguageDistributionRow({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
    super.key,
  });

  final String name;
  final double percent;
  final double delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.dot),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(name, style: AppTypography.titleSmall)),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
          style: AppTypography.labelSmall.copyWith(
            color: delta >= 0 ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
