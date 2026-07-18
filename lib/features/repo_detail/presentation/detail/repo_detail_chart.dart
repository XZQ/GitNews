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
    final hasMeaningfulComparison = _isComparable(primary, compare);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;
              final sectionHeader = SectionHeader(
                title: l10n.tr('repo_detail.section.star_trend'),
                subtitle: l10n.tr(
                  hasMeaningfulComparison ? 'repo_detail.section.star_trend.subtitle_compare' : 'repo_detail.section.star_trend.subtitle',
                ),
              );
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetricBasisBadge(
                    basis: widget.digest.repo.trendBasis,
                    compact: isCompact,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _WindowSelector(
                    value: _window,
                    onChanged: (value) {
                      setState(() => _window = value);
                    },
                  ),
                ],
              );
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionHeader,
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: controls,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: sectionHeader),
                  controls,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(
            series: [
              ChartSeries(
                values: primary,
                color: Theme.of(context).colorScheme.primary,
              ),
              if (hasMeaningfulComparison) ChartSeries(values: compare, color: AppColors.info),
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

  bool _isComparable(List<double> primary, List<double> compare) {
    if (primary.isEmpty || compare.isEmpty || !compare.any((value) => value != 0)) {
      return false;
    }
    final primaryMax = primary.map((value) => value.abs()).reduce((a, b) => a > b ? a : b);
    final compareMax = compare.map((value) => value.abs()).reduce((a, b) => a > b ? a : b);
    if (primaryMax == 0 || compareMax == 0) {
      return false;
    }
    final ratio = compareMax / primaryMax;
    return ratio >= 0.2 && ratio <= 5;
  }
}

/*
*仓库趋势的时间窗选择器。
*/
class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.value, required this.onChanged});

  // 当前选中的天数。
  final int value;

  // 用户切换时间窗后的回调。
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(l10n.tr('repo_detail.window.7d'))),
        ButtonSegment(value: 30, label: Text(l10n.tr('repo_detail.window.30d'))),
        ButtonSegment(value: 90, label: Text(l10n.tr('repo_detail.window.90d'))),
      ],
      selected: {value},
      onSelectionChanged: (values) {
        onChanged(values.first);
      },
      showSelectedIcon: false,
    );
  }
}
