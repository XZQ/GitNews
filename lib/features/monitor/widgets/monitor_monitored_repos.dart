import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../../core/domain/repo_entity.dart';

class MonitorMonitoredRepos extends StatelessWidget {
  const MonitorMonitoredRepos({required this.repos, super.key});

  final List<RepoEntity> repos;

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
          if (repos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off_rounded,
                message: '没有匹配的监控仓库',
              ),
            )
          else
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

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trend =
        repo.trend ?? DemoData.generateStarTrend(repo.starCount - 5000, 5000);
    return InkWell(
      onTap: () =>
          context.go('/monitor/detail/${Uri.encodeComponent(repo.fullName)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(
                color: Color(repo.accentArgb).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language.isNotEmpty ? repo.language[0] : '?',
                style: AppTypography.labelMedium.copyWith(
                  color: Color(repo.accentArgb),
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
              values: trend,
              color: AppColors.success,
              width: 90,
              height: 32,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs2,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
