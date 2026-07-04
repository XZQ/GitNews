import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/repo_tile.dart';
import '../../../../shared/widgets/section_header.dart';

class ProjectPopularRepos extends StatelessWidget {
  const ProjectPopularRepos({required this.repos, super.key});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            child: SectionHeader(
              title: l10n.tr('project.section.popular.title'),
              subtitle: l10n.tr('project.section.popular.subtitle'),
            ),
          ),
          if (repos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: EmptyView(
                icon: Icons.search_off_rounded,
                message: '没有匹配的热门仓库',
              ),
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

class ProjectRecentlyUpdated extends StatelessWidget {
  const ProjectRecentlyUpdated({required this.repos, super.key});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            child: SectionHeader(
              title: l10n.tr('project.section.recent.title'),
              subtitle: l10n.tr('project.section.recent.subtitle'),
            ),
          ),
          if (repos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: EmptyView(
                icon: Icons.search_off_rounded,
                message: '没有匹配的最近活跃仓库',
              ),
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
