import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/project_repository.dart';

class ProjectSummaryMetrics extends StatelessWidget {
  const ProjectSummaryMetrics({required this.digest, super.key});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weeklyStars = digest.repos.fold<int>(0, (sum, repo) => sum + repo.starDelta);
    final forks = digest.repos.fold<int>(0, (sum, repo) => sum + repo.forkCount);
    return Row(
      children: [
        Expanded(
          child: _MetricBlock(
            label: l10n.tr('project.metric.weekly_stars'),
            value: _compactNumber(weeklyStars),
            delta: '+${digest.repos.length} repos',
            color: AppColors.success,
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricBlock(
            label: l10n.tr('project.metric.new_repos'),
            value: _compactNumber(digest.repos.length),
            delta: '动态热榜',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.bookmark_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricBlock(
            label: l10n.tr('project.metric.active_contributors'),
            value: _compactNumber(digest.contributors.length),
            delta: 'GitHub',
            color: AppColors.info,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MetricBlock(
          label: l10n.tr('project.metric.total_forks'),
          value: _compactNumber(forks),
          delta: '+forks',
          color: AppColors.warning,
          icon: Icons.call_split_rounded,
        ))
      ],
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(label, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)))
          ]),
          const SizedBox(height: AppSpacing.sm2),
          Text(value, style: AppTypography.headlineMedium.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.xxs),
          Text(delta, style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}
