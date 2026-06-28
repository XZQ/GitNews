import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_hero_header.dart';
import '../../domain/tech_hotspot_models.dart';

Color techHeatColor(int heat) {
  if (heat >= 90) return AppColors.danger;
  if (heat >= 75) return AppColors.warning;
  return AppColors.info;
}

class TechHotspotDetailTopicHeader extends StatelessWidget {
  const TechHotspotDetailTopicHeader({required this.topic, super.key});

  final TechTopic topic;

  @override
  Widget build(BuildContext context) {
    final heatColor = techHeatColor(topic.heat);
    return GradientHeroHeader(
      accent: heatColor,
      title: topic.name,
      titleStyle: AppTypography.headlineMedium,
      badges: [
        HeroBadge(label: topic.category, color: heatColor),
        HeroBadge(
          label: '热度 ${topic.heat}',
          color: heatColor,
          icon: Icons.local_fire_department_rounded,
        ),
      ],
      trailing: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _MetricTile(
            icon: Icons.trending_up_rounded,
            label: '周环比',
            value: '+${topic.growth.toStringAsFixed(1)}%',
          ),
          _MetricTile(
            icon: Icons.forum_rounded,
            label: '讨论',
            value: '${topic.mentions}',
          ),
          _MetricTile(
            icon: Icons.book_outlined,
            label: '相关仓库',
            value: '${topic.relatedRepos}',
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label · ',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
