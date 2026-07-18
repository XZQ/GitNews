import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/project_providers.dart';
import 'widgets/project_page_skeleton.dart';
import 'widgets/project_secondary_cards.dart';

/* 
*二级:探索发现(话题 → 仓库 → 推荐)。
*/
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectDigestProvider);
    return SecondaryPageScaffold(
      title: l10n.tr('project.explore.title'),
      subtitle: l10n.tr('common.secondary_page_subtitle'),
      icon: Icons.explore_outlined,
      fallbackPath: '/project',
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
      data: (digest) => digest.isEmpty ? EmptyView(icon: Icons.explore_outlined, message: l10n.tr('project.explore.empty')) : _DigestView(digest: digest),
      loading: () => const ProjectPageSkeleton(),
      error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(projectDigestProvider)),
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
        ProjectRepoListCard(
          title: AppLocalizations.of(context).tr('project.explore.recommended_repos'),
          subtitle: AppLocalizations.of(context).tr('project.explore.recommended_repos.subtitle').replaceAll('{n}', digest.repos.length.toString()),
          repos: digest.repos,
        ),
        const SizedBox(height: AppSpacing.lg),
        ProjectContributorsCard(
          title: AppLocalizations.of(context).tr('project.explore.followable_devs'),
          subtitle: AppLocalizations.of(context).tr('project.explore.followable_devs.subtitle'),
          contributors: digest.contributors,
        )
      ],
    );
  }
}

class _HotChipsCard extends ConsumerWidget {
  const _HotChipsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final chips = <_TopicChipSpec>[
      _TopicChipSpec(label: l10n.tr('project.topic.ai_agent'), color: colors.primary),
      _TopicChipSpec(label: l10n.tr('project.topic.llm'), color: AppColors.info),
      _TopicChipSpec(label: l10n.tr('project.topic.devtools'), color: AppColors.success),
      _TopicChipSpec(label: l10n.tr('project.topic.rag'), color: AppColors.warning),
      const _TopicChipSpec(label: 'Web3', color: AppColors.danger),
      _TopicChipSpec(label: l10n.tr('project.topic.cloud_native'), color: colors.primary),
      _TopicChipSpec(label: l10n.tr('project.topic.data_infra'), color: AppColors.info),
      _TopicChipSpec(label: l10n.tr('project.topic.security'), color: AppColors.success)
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tr('project.explore.hot_topics'), subtitle: l10n.tr('project.explore.hot_topics.subtitle')),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final c in chips) ProjectTopicChip(label: c.label, color: c.color)])
        ],
      ),
    );
  }
}
