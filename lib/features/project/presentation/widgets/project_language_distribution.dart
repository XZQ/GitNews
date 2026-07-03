import 'package:flutter/material.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/i18n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.section.language.title'),
            subtitle: l10n.tr('project.section.language.subtitle'),
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
                      const SizedBox(width: AppSpacing.xs2),
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
