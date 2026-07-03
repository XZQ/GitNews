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
        _RecommendReposCard(repos: digest.repos),
        const SizedBox(height: AppSpacing.lg),
        _FollowContributorsCard(contributors: digest.contributors),
      ],
    );
  }
}

class _HotTopicsCard extends StatelessWidget {
  const _HotTopicsCard();

  @override
  Widget build(BuildContext context) {
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
                _TopicCard(
                  label: t.label,
                  desc: l10n
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

class _RecommendReposCard extends StatelessWidget {
  const _RecommendReposCard({required this.repos});

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
              title: l10n.tr('project.discover.recommended_repos'),
              subtitle: l10n.tr('project.discover.recommended_repos.subtitle'),
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

class _FollowContributorsCard extends StatelessWidget {
  const _FollowContributorsCard({required this.contributors});

  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.discover.recommended_devs'),
            subtitle: l10n.tr('project.discover.recommended_devs.subtitle'),
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.label,
    required this.desc,
    required this.color,
  });
  final String label;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
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
            desc,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
