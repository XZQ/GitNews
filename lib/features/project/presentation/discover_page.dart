import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/project_providers.dart';
import 'widgets/project_page_skeleton.dart';
import 'widgets/project_secondary_cards.dart';

/// 二级:发现推荐(收藏夹 + 热门仓库推荐)。
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.discover.title')),
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

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final AsyncValue<ProjectDigest> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return state.when(
      data: (digest) => digest.isEmpty
          ? EmptyView(
              icon: Icons.lightbulb_outline_rounded,
              message: l10n.tr('project.discover.empty'),
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

class _TopicSpec {
  const _TopicSpec({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
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
        const _HotTopicsCard(),
        const SizedBox(height: AppSpacing.lg),
        ProjectRepoListCard(
          title: AppLocalizations.of(context)
              .tr('project.discover.recommended_repos'),
          subtitle: AppLocalizations.of(context)
              .tr('project.discover.recommended_repos.subtitle'),
          repos: digest.repos,
        ),
        const SizedBox(height: AppSpacing.lg),
        ProjectContributorsCard(
          title: AppLocalizations.of(context)
              .tr('project.discover.recommended_devs'),
          subtitle: AppLocalizations.of(context)
              .tr('project.discover.recommended_devs.subtitle'),
          contributors: digest.contributors,
        ),
      ],
    );
  }
}

class _HotTopicsCard extends ConsumerWidget {
  const _HotTopicsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final topics = <_TopicSpec>[
      _TopicSpec(
        label: l10n.tr('project.topic.ai_agent'),
        count: 32,
        color: colors.primary,
      ),
      _TopicSpec(
        label: l10n.tr('project.topic.llm'),
        count: 128,
        color: AppColors.info,
      ),
      _TopicSpec(
        label: l10n.tr('project.topic.devtools'),
        count: 64,
        color: AppColors.success,
      ),
      _TopicSpec(
        label: l10n.tr('project.topic.rag'),
        count: 24,
        color: AppColors.warning,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.discover.topic_popular'),
            subtitle: l10n.tr('project.discover.topic_popular.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in topics)
                ProjectTopicCard(
                  label: t.label,
                  description: l10n
                      .tr('project.discover.topic_repos')
                      .replaceAll('{n}', t.count.toString()),
                  color: t.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
