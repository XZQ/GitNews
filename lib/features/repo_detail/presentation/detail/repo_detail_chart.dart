import 'package:flutter/material.dart';

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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Star 增长趋势',
                  subtitle: '最近 30 天 · 包含本仓库 + 同期均',
                ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7天')),
                  ButtonSegment(value: 30, label: Text('30天')),
                  ButtonSegment(value: 90, label: Text('90天')),
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
