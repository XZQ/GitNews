import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_activity_event.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/i18n/relative_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/section_header.dart';

class ActivityEventsCard extends StatelessWidget {
  const ActivityEventsCard({required this.activities, super.key});

  final List<RepoActivityEvent> activities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (activities.isEmpty) {
      return EmptyView(icon: Icons.history_toggle_off_rounded, message: l10n.tr('project.activity.empty'));
    }
    return AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(child: SectionHeader(title: l10n.tr('project.activity.recent_7d'), subtitle: l10n.tr('project.activity.recent_7d.subtitle'))),
                const SizedBox(width: AppSpacing.sm),
                MetricBasisBadge(basis: activities.first.basis)
              ],
            ),
          ),
          for (var index = 0; index < activities.length; index++) ...[if (index != 0) const Divider(height: 1), _EventTile(activity: activities[index])]
        ]));
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.activity});

  final RepoActivityEvent activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = _visualFor(context, activity.type);
    final actor = activity.actorLogin.isEmpty ? '' : '@${activity.actorLogin} · ';
    final time = formatRelativeTime(l10n, activity.occurredAt);
    final semanticsLabel = l10n.tr('a11y.activity_open').replaceAll('{repo}', activity.repoFullName).replaceAll('{title}', activity.title);
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => context.go('/project/detail/${Uri.encodeComponent(activity.repoFullName)}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: visual.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(visual.icon, color: visual.color, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.repoFullName, style: AppTypography.titleSmall),
                      Text(
                        activity.title,
                        style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$actor$time',
                        style: AppTypography.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_ActivityVisual _visualFor(BuildContext context, RepoActivityType type) {
  return switch (type) {
    RepoActivityType.push => const _ActivityVisual(icon: Icons.commit, color: AppColors.success),
    RepoActivityType.issues => const _ActivityVisual(icon: Icons.bug_report_outlined, color: AppColors.warning),
    RepoActivityType.pullRequest => const _ActivityVisual(icon: Icons.merge_type_rounded, color: AppColors.info),
    RepoActivityType.release => const _ActivityVisual(icon: Icons.new_releases_outlined, color: AppColors.brand),
    RepoActivityType.create => _ActivityVisual(icon: Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
    RepoActivityType.other => _ActivityVisual(icon: Icons.history_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant)
  };
}

class _ActivityVisual {
  const _ActivityVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
