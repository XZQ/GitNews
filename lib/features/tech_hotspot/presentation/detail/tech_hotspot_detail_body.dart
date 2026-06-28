import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/tech_hotspot_models.dart';

class TechHotspotDetailSummary extends StatelessWidget {
  const TechHotspotDetailSummary({required this.topic, super.key});

  final TechTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '主题概述', subtitle: '编辑综述与近期变化'),
          const SizedBox(height: AppSpacing.md),
          Text(
            topic.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class TechHotspotDetailLanguages extends StatelessWidget {
  const TechHotspotDetailLanguages({required this.languages, super.key});

  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '相关语言', subtitle: '主题领域内活跃语言分布'),
          const SizedBox(height: AppSpacing.md),
          for (final lang in languages.take(5)) ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(lang.color),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(lang.name, style: AppTypography.labelLarge),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${lang.percent.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${lang.delta >= 0 ? '+' : ''}${lang.delta.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: lang.delta >= 0
                        ? AppColors.trendUp
                        : AppColors.trendDown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
