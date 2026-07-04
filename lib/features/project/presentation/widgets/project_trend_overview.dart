import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/star_trend_chart.dart';
import '../../domain/project_repository.dart';

class ProjectTrendOverview extends StatelessWidget {
  const ProjectTrendOverview({required this.digest, super.key});

  final ProjectDigest digest;

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
                values: _safeTrend(digest.primaryTrend),
                color: Theme.of(context).colorScheme.primary,
              ),
              ChartSeries(
                values: _safeTrend(digest.secondaryTrend),
                color: AppColors.info,
              ),
            ],
            height: 220,
          ),
        ],
      ),
    );
  }

  List<double> _safeTrend(List<double> values) {
    if (values.isNotEmpty) return values;
    final stars =
        digest.repos.fold<int>(0, (sum, repo) => sum + repo.starDelta);
    return List<double>.generate(
      7,
      (index) => (stars * (0.7 + index * 0.05)).roundToDouble(),
    );
  }
}
