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
import '../../../shared/widgets/section_header.dart';
import '../../repo_detail/domain/entities.dart';
import '../application/project_providers.dart';
import 'widgets/project_page_skeleton.dart';

/// 二级:活动速览(Commit / Issue / Release 流)。
class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(projectDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('project.activity.title')),
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

class _EventSpec {
  const _EventSpec({
    required this.repo,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String repo;
  final String title;
  final String time;
  final IconData icon;
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
              icon: Icons.history_toggle_off_rounded,
              message: l10n.tr('project.activity.empty'),
            )
          : _DigestView(digest: digest),
      loading: () => const ProjectPageSkeleton(blocks: [320, 220]),
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
        const _ActivityEventsCard(),
        const SizedBox(height: AppSpacing.lg),
        _ContributorsCard(contributors: digest.contributors),
      ],
    );
  }
}

class _ActivityEventsCard extends StatelessWidget {
  const _ActivityEventsCard();

  static const List<_EventSpec> events = [
    _EventSpec(
      repo: 'openai/whisper',
      title: 'feat: support streaming response',
      time: '4 小时前 · main',
      icon: Icons.commit,
      color: AppColors.success,
    ),
    _EventSpec(
      repo: 'anthropics/claude-code',
      title: 'fix: cache invalidation race',
      time: '6 小时前 · main',
      icon: Icons.bug_report_outlined,
      color: AppColors.info,
    ),
    _EventSpec(
      repo: 'denoland/deno',
      title: 'chore: bump dependencies',
      time: '昨天 18:24 · main',
      icon: Icons.upgrade,
      color: AppColors.warning,
    ),
    _EventSpec(
      repo: 'mrdoob/three.js',
      title: 'release v0.42.1',
      time: '3 天前',
      icon: Icons.local_fire_department,
      color: AppColors.brand,
    ),
    _EventSpec(
      repo: 'withastro/astro',
      title: 'docs: new tutorial',
      time: '3 天前 · main',
      icon: Icons.description,
      color: AppColors.info,
    ),
    _EventSpec(
      repo: 'vitejs/vite',
      title: 'feat: optimize build pipeline',
      time: '4 天前',
      icon: Icons.flash_on,
      color: AppColors.success,
    ),
  ];

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
              title: l10n.tr('project.activity.recent_7d'),
              subtitle: l10n.tr('project.activity.recent_7d.subtitle'),
            ),
          ),
          for (var i = 0; i < events.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _EventTile(
              repo: events[i].repo,
              title: events[i].title,
              time: events[i].time,
              icon: events[i].icon,
              color: events[i].color,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContributorsCard extends StatelessWidget {
  const _ContributorsCard({required this.contributors});

  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.activity.developers'),
            subtitle: l10n.tr('project.activity.developers.subtitle'),
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
            ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.repo,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String repo;
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go('/project/detail/${Uri.encodeComponent(repo)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo, style: AppTypography.titleSmall),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
