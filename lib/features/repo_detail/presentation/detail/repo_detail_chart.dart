import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/star_trend_chart.dart';
import '../../domain/repo_detail_repository.dart';

class RepoDetailChart extends StatefulWidget {
  const RepoDetailChart({required this.digest, super.key});

  final RepoDetailDigest digest;

  @override
  State<RepoDetailChart> createState() => _RepoDetailChartState();
}

class _RepoDetailChartState extends State<RepoDetailChart> {
  int _window = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = _windowed(widget.digest.primaryTrend);
    final compare = _windowed(widget.digest.compareTrend);
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
              DataProvenanceBadge(
                provenance: widget.digest.repo.trendProvenance,
                compact: false,
              ),
              const SizedBox(width: AppSpacing.md),
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
                selected: {_window},
                onSelectionChanged: (values) {
                  setState(() => _window = values.first);
                },
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(
            series: [
              ChartSeries(
                values: primary,
                color: Theme.of(context).colorScheme.primary,
              ),
              ChartSeries(values: compare, color: AppColors.info),
            ],
            height: 220,
          ),
        ],
      ),
    );
  }

  List<double> _windowed(List<double> values) {
    if (values.length <= _window) {
      return values;
    }
    return values.sublist(values.length - _window);
  }
}
