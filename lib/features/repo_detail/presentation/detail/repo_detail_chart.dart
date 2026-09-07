import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/repo_growth_chart.dart';
import '../../../../shared/widgets/section_header.dart';
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;
              final sectionHeader = SectionHeader(title: l10n.tr('repo_detail.section.star_trend'), subtitle: l10n.tr('growth.subtitle'));
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetricBasisBadge(basis: widget.digest.repo.trendBasis, compact: isCompact),
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
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls),
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
          RepoGrowthChart(repos: [widget.digest.repo], days: _window),
        ],
      ),
    );
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
      ],
      selected: {value},
      onSelectionChanged: (values) {
        onChanged(values.first);
      },
      showSelectedIcon: false,
    );
  }
}
