import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/demo_data_mappers.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/repo_tile.dart';
import '../../../../shared/widgets/section_header.dart';

class ProjectPopularRepos extends StatelessWidget {
  const ProjectPopularRepos({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos =
        DemoData.trending.map((e) => e.toEntity()).toList(growable: false);
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
  const ProjectRecentlyUpdated({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos =
        DemoData.recent.map((e) => e.toEntity()).toList(growable: false);
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
