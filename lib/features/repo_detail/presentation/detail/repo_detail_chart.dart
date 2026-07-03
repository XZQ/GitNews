import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/star_trend_chart.dart';
import '../../domain/repo_detail_repository.dart';

class RepoDetailChart extends StatelessWidget {
  const RepoDetailChart({required this.digest, super.key});

  final RepoDetailDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: l10n.tr('repo_detail.section.star_trend'),
                  subtitle: l10n.tr('repo_detail.section.star_trend.subtitle'),
                ),
              ),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 7,
                    label: Text(l10n.tr('repo_detail.window.7d')),
                  ),
                  ButtonSegment(
                    value: 30,
                    label: Text(l10n.tr('repo_detail.window.30d')),
                  ),
                  ButtonSegment(
                    value: 90,
                    label: Text(l10n.tr('repo_detail.window.90d')),
                  ),
                ],
                selected: const {30},
                onSelectionChanged: (_) {},
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(
            series: [
              ChartSeries(
                values: digest.primaryTrend,
                color: Theme.of(context).colorScheme.primary,
              ),
              ChartSeries(
                values: digest.compareTrend,
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
