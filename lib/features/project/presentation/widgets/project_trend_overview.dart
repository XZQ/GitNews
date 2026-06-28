import 'package:flutter/material.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/star_trend_chart.dart';

class ProjectTrendOverview extends StatelessWidget {
  const ProjectTrendOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '趋势对比',
            subtitle: '最近 7 天 vs 上周',
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
