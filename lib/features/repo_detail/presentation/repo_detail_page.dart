import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../application/repo_detail_providers.dart';
import '../domain/repo_detail_repository.dart';
import 'detail/repo_detail_activity.dart';
import 'detail/repo_detail_chart.dart';
import 'detail/repo_detail_contributors.dart';
import 'detail/repo_detail_header.dart';
import 'detail/repo_detail_sidebar.dart';
import 'detail/repo_detail_skeleton.dart';
import 'detail/repo_detail_stats.dart';

class RepoDetailPage extends ConsumerWidget {
  const RepoDetailPage({required this.fullName, super.key});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(repoDetailResultProvider(fullName));
    final content = ref.watch(localContentControllerProvider);
    final decodedFullName = Uri.decodeComponent(fullName);
    final actionRepo = state.asData?.value.data.repo;
    final title = state.maybeWhen(
      data: (result) => result.data.repo.fullName,
      orElse: () => l10n.tr('repo_detail.title'),
    );
    final subtitle = state.maybeWhen(
      data: (result) => result.data.repo.description,
      orElse: () => l10n.tr('common.secondary_page_subtitle'),
    );
    final actions = [
      HeaderAction(
        icon: content.isBookmarked(decodedFullName) ? Icons.bookmark : Icons.bookmark_border,
        tooltip: l10n.tr(content.isBookmarked(decodedFullName) ? 'a11y.bookmark_remove' : 'a11y.bookmark_add'),
        onPressed: actionRepo == null ? null : () => ref.read(localContentControllerProvider.notifier).toggleBookmark(actionRepo),
      ),
      HeaderAction(
        icon: content.isMonitored(decodedFullName) ? Icons.notifications_active : Icons.notifications_none,
        tooltip: l10n.tr('repo_detail.subscribe'),
        onPressed: actionRepo == null
            ? null
            : () {
                ref.read(localContentControllerProvider.notifier).addMonitor(actionRepo);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tr('repo_detail.subscribed').replaceAll('{name}', decodedFullName))));
              },
      ),
    ];
    return SecondaryPageScaffold(
        title: title,
        subtitle: subtitle,
        icon: Icons.code_rounded,
        fallbackPath: '/home',
        actions: actions,
        body: state.when(
            data: (result) {
              final digest = result.data;
              return ResponsiveLayout(
                compact: (_) => _Mobile(digest: digest, freshness: result.freshness),
                medium: (_) => CenteredContent(child: _Desktop(digest: digest, freshness: result.freshness)),
                expanded: (_) => CenteredContent(child: _Desktop(digest: digest, freshness: result.freshness)),
              );
            },
            loading: () => const RepoDetailSkeleton(),
            error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(repoDetailResultProvider(fullName)))));
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.digest, required this.freshness});

  final RepoDetailDigest digest;
  final DataFreshness freshness;

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
        RepoDetailHeader(repo: digest.repo, freshness: freshness, compact: true),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailStats(repo: digest.repo, contributorCount: digest.contributors.length),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailChart(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailContributors(contributors: digest.contributors),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailActivity(activities: digest.activities)
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({required this.digest, required this.freshness});

  final RepoDetailDigest digest;
  final DataFreshness freshness;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        RepoDetailHeader(repo: digest.repo, freshness: freshness),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(flex: 8, child: _Left(digest: digest)), const SizedBox(width: AppSpacing.lg), Expanded(flex: 4, child: _Right(relatedRepos: digest.relatedRepos))],
        )
      ],
    );
  }
}

class _Left extends StatelessWidget {
  const _Left({required this.digest});

  final RepoDetailDigest digest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepoDetailStats(repo: digest.repo, contributorCount: digest.contributors.length),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailChart(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailContributors(contributors: digest.contributors),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailActivity(activities: digest.activities)
      ],
    );
  }
}

class _Right extends StatelessWidget {
  const _Right({required this.relatedRepos});

  final List<RepoEntity> relatedRepos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RepoDetailAboutCard(),
        const SizedBox(height: AppSpacing.lg),
        const RepoDetailTopicsCard(),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailRelatedReposCard(repos: relatedRepos)
      ],
    );
  }
}
