import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

class RepoDetailActivity extends StatelessWidget {
  const RepoDetailActivity({required this.activities, super.key});

  final List<RepoActivityEvent> activities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (activities.isEmpty) {
      return EmptyView(icon: Icons.history_toggle_off_rounded, message: l10n.tr('project.activity.empty'));
    }
    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(child: SectionHeader(title: l10n.tr('repo_detail.section.activity'), subtitle: l10n.tr('repo_detail.section.activity.subtitle'))),
          const SizedBox(width: AppSpacing.sm),
          MetricBasisBadge(basis: activities.first.basis)
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      for (var index = 0; index < activities.length; index++) ...[if (index != 0) const Divider(height: 1), _ActivityTile(activity: activities[index])]
    ]));
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final RepoActivityEvent activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = _visualFor(context, activity.type);
    final actor = activity.actorLogin.isEmpty ? '' : '@${activity.actorLogin} · ';
    final time = formatRelativeTime(l10n, activity.occurredAt);
    final key = activity.htmlUrl == null ? 'a11y.activity_item' : 'a11y.activity_open';
    final label = l10n.tr(key).replaceAll('{repo}', activity.repoFullName).replaceAll('{title}', activity.title).replaceAll('{time}', time);
    return Semantics(
      container: true,
      button: activity.htmlUrl != null,
      label: label,
      child: ExcludeSemantics(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: activity.htmlUrl == null ? null : () => _open(activity.htmlUrl!),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: visual.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(visual.icon, color: visual.color, size: 18),
          ),
          title: Text(
            activity.title,
            style: AppTypography.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('$actor$time', style: AppTypography.labelSmall),
        ),
      ),
    );
  }

  Future<void> _open(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
