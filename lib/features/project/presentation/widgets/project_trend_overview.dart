import 'package:flutter/material.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/star_trend_chart.dart';

class ProjectTrendOverview extends StatelessWidget {
  const ProjectTrendOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.section.trend.title'),
            subtitle: l10n.tr('project.section.trend.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(
            series: [
              ChartSeries(
                values: DemoData.generateStarTrend(42000, 4200),
                color: Theme.of(context).colorScheme.primary,
              ),
              ChartSeries(
                values: DemoData.generateStarTrend(38500, 2800),
                color: AppColors.info,
              ),
            ],
            height: 220,
          ),
        ],
      ),
    );
  }
}
