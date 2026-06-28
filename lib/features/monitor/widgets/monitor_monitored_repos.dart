import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

class MonitorMonitoredRepos extends StatelessWidget {
  const MonitorMonitoredRepos({required this.repos, super.key});

  final List<DemoRepo> repos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(
                title: '我的监控仓库',
                subtitle: '近 30 天 Star 增速与告警',
              ),
            ),
          ),
          SliverList.builder(
            itemCount: repos.length,
            itemBuilder: (context, i) {
              return Column(
                children: [
                  if (i != 0) const Divider(height: 1),
                  MonitorMonitoredRow(repo: repos[i]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class MonitorMonitoredRow extends StatelessWidget {
  const MonitorMonitoredRow({required this.repo, super.key});

  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () =>
          context.go('/repo_detail/${Uri.encodeComponent(repo.fullName)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(repo.color).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language.isNotEmpty ? repo.language[0] : '?',
                style: AppTypography.labelMedium.copyWith(
                  color: Color(repo.color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, style: AppTypography.titleSmall),
                  Text(
                    repo.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Sparkline(
              values: DemoData.generateStarTrend(repo.starCount - 5000, 5000),
              color: AppColors.success,
              width: 90,
              height: 32,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm - 2,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.xs + 2),
              ),
              child: Text(
                '正常',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
