import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/domain/repo_entity.dart';
import '../../repo_detail/domain/entities.dart';
import '../application/project_providers.dart';
import 'widgets/project_page_skeleton.dart';

/// 二级:探索发现(话题 → 仓库 → 推荐)。
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.explore.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/project'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => _Body(state: state),
        medium: (_) => CenteredContent(child: _Body(state: state)),
        expanded: (_) => CenteredContent(child: _Body(state: state)),
      ),
    );
  }
}

class _TopicChipSpec {
  const _TopicChipSpec({required this.label, required this.color});
  final String label;
  final Color color;
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final AsyncValue<ProjectDigest> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return state.when(
      data: (digest) => digest.isEmpty
          ? EmptyView(
              icon: Icons.explore_outlined,
              message: l10n.tr('project.explore.empty'),
            )
          : _DigestView(digest: digest),
      loading: () => const ProjectPageSkeleton(),
      error: (error, stack) => ErrorView(
        error: error.asAppException(stack),
        onRetry: () => ref.invalidate(projectDigestProvider),
      ),
    );
  }
}

class _DigestView extends StatelessWidget {
  const _DigestView({required this.digest});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        const _HotChipsCard(),
        const SizedBox(height: AppSpacing.lg),
        _ExploreReposCard(repos: digest.repos),
        const SizedBox(height: AppSpacing.lg),
        _ExploreContributorsCard(contributors: digest.contributors),
      ],
    );
  }
}

class _HotChipsCard extends StatelessWidget {
  const _HotChipsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final chips = <_TopicChipSpec>[
      _TopicChipSpec(
        label: l10n.tr('project.topic.ai_agent'),
        color: colors.primary,
      ),
      _TopicChipSpec(
        label: l10n.tr('project.topic.llm'),
        color: AppColors.info,
      ),
      _TopicChipSpec(
        label: l10n.tr('project.topic.devtools'),
        color: AppColors.success,
      ),
      _TopicChipSpec(
        label: l10n.tr('project.topic.rag'),
        color: AppColors.warning,
      ),
      const _TopicChipSpec(label: 'Web3', color: AppColors.danger),
      _TopicChipSpec(
        label: l10n.tr('project.topic.cloud_native'),
        color: colors.primary,
      ),
      _TopicChipSpec(
        label: l10n.tr('project.topic.data_infra'),
        color: AppColors.info,
      ),
      _TopicChipSpec(
        label: l10n.tr('project.topic.security'),
        color: AppColors.success,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.explore.hot_topics'),
            subtitle: l10n.tr('project.explore.hot_topics.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in chips) _TopicChip(label: c.label, color: c.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreReposCard extends StatelessWidget {
  const _ExploreReposCard({required this.repos});

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
              title: l10n.tr('project.explore.recommended_repos'),
              subtitle: l10n
                  .tr('project.explore.recommended_repos.subtitle')
                  .replaceAll('{n}', repos.length.toString()),
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

class _ExploreContributorsCard extends StatelessWidget {
  const _ExploreContributorsCard({required this.contributors});

  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.explore.followable_devs'),
            subtitle: l10n.tr('project.explore.followable_devs.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in contributors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                    Color(c.avatarAccentArgb).withValues(alpha: 0.16),
                child: Text(
                  c.login[0].toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    color: Color(c.avatarAccentArgb),
                  ),
                ),
              ),
              title: Text(c.login, style: AppTypography.titleSmall),
              subtitle: Text(
                l10n
                    .tr('project.activity.contrib')
                    .replaceAll('{n}', c.contributions.toString()),
              ),
              trailing: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n
                            .tr('project.discover.followed')
                            .replaceAll('{name}', c.login),
                      ),
                    ),
                  );
                },
                child: Text(l10n.tr('project.discover.follow')),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
