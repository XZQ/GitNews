import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/tech_hotspot_models.dart';

/// 技术主题卡片(网格单元)。
class TechHotspotTopicCard extends StatelessWidget {
  const TechHotspotTopicCard({
    required this.topic,
    required this.onTap,
    super.key,
  });

  final TechTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final heatColor = _heatColor(topic.heat);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant.withValues(
                alpha: isLight ? 0.58 : 1,
              ),
              width: isLight ? 0.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: heatColor.withValues(alpha: 0.14),
                      border: Border.all(
                        color: heatColor.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      topic.category,
                      style: AppTypography.labelSmall.copyWith(
                        color: heatColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _HeatIndicator(value: topic.heat, color: heatColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                topic.name,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                topic.summary,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 12,
                    color: AppColors.trendUp,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '+${topic.growth.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.trendUp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.forum_rounded,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${topic.mentions}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.book_outlined,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${topic.relatedRepos}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _heatColor(int heat) {
    if (heat >= 90) return AppColors.danger;
    if (heat >= 75) return AppColors.warning;
    return AppColors.info;
  }
}

class _HeatIndicator extends StatelessWidget {
  const _HeatIndicator({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department_rounded, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
