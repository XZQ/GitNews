import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/repo_tile.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../repo_detail/domain/entities.dart';
import '../../application/project_providers.dart';

class ProjectRepoListCard extends StatelessWidget {
  const ProjectRepoListCard({
    required this.title,
    required this.subtitle,
    required this.repos,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(title: title, subtitle: subtitle),
          ),
          for (var i = 0; i < repos.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: repos[i],
              onTap: () => context.go(
                '/project/detail/${Uri.encodeComponent(repos[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProjectContributorsCard extends ConsumerWidget {
  const ProjectContributorsCard({
    required this.title,
    required this.subtitle,
    required this.contributors,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(localContentControllerProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          for (final contributor in contributors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                    Color(contributor.avatarAccentArgb).withValues(alpha: 0.16),
                child: Text(
                  contributor.login[0].toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    color: Color(contributor.avatarAccentArgb),
                  ),
                ),
              ),
              title: Text(contributor.login, style: AppTypography.titleSmall),
              subtitle: Text(
                l10n
                    .tr('project.activity.contrib')
                    .replaceAll('{n}', contributor.contributions.toString()),
              ),
              trailing: OutlinedButton(
                onPressed: () => ref
                    .read(localContentControllerProvider.notifier)
                    .toggleDeveloper(contributor.login),
                child: Text(
                  content.isFollowingDeveloper(contributor.login)
                      ? '已关注'
                      : l10n.tr('project.discover.follow'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProjectTopicChip extends StatelessWidget {
  const ProjectTopicChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () {
            ref.read(projectSearchQueryProvider.notifier).state = label;
            context.go('/project');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProjectTopicCard extends StatelessWidget {
  const ProjectTopicCard({
    required this.label,
    required this.description,
    required this.color,
    super.key,
  });

  final String label;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Consumer(
      builder: (context, ref, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            ref.read(projectSearchQueryProvider.notifier).state = label;
            context.go('/project');
          },
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
