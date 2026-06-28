import 'package:flutter/material.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class ProjectLanguageDistribution extends StatelessWidget {
  const ProjectLanguageDistribution({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '语言分布',
            subtitle: '热门仓库的编程语言占比',
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final l in DemoData.languages.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(l.color),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l.name, style: AppTypography.bodyMedium),
                      ),
                      Text(
                        '${l.percent.toStringAsFixed(1)}%',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(width: AppSpacing.sm - 2),
                      Text(
                        '${l.delta >= 0 ? '+' : ''}${l.delta.toStringAsFixed(1)}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: l.delta >= 0
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
