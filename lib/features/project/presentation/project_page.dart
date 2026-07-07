import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../application/project_providers.dart';
import 'widgets/project_language_distribution.dart';
import 'widgets/project_page_header.dart';
import 'widgets/project_page_skeleton.dart';
import 'widgets/project_repo_lists.dart';
import 'widgets/project_summary_metrics.dart';
import 'widgets/project_trend_overview.dart';

/* "项目 / 报告 / 探索" 三栏内容,集中在一个 Tab。 */
class ProjectPage extends ConsumerWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(filteredProjectDigestProvider);
    final query = ref.watch(projectSearchQueryProvider).trim();
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('project.title'))) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty && query.isNotEmpty) {
            return EmptyView(
              icon: Icons.search_off_rounded,
              message:
                  l10n.tr('project.empty_search').replaceAll('{query}', query),
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Mobile(digest: digest),
            medium: (_) => _Desktop(digest: digest),
            expanded: (_) => _Desktop(digest: digest),
          );
        },
        loading: () => const ProjectPageSkeleton(),
        error: (error, stack) => ErrorView(
          error: error.asAppException(stack),
          onRetry: () => ref.invalidate(projectDigestProvider),
        ),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.digest});

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
        ProjectSummaryMetrics(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        ProjectLanguageDistribution(repos: digest.repos),
        const SizedBox(height: AppSpacing.lg),
        ProjectTrendOverview(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        ProjectPopularRepos(repos: digest.repos),
        const SizedBox(height: AppSpacing.lg),
        ProjectRecentlyUpdated(repos: _recentRepos(digest.repos)),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({required this.digest});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectSummaryMetrics(digest: digest),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 390,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: ProjectTrendOverview(digest: digest),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: ProjectLanguageDistribution(repos: digest.repos),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ProjectPopularRepos(repos: digest.repos),
                const SizedBox(height: AppSpacing.lg),
                ProjectRecentlyUpdated(repos: _recentRepos(digest.repos)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<RepoEntity> _recentRepos(List<RepoEntity> repos) {
  if (repos.length <= 6) return repos;
  return repos.skip(6).toList(growable: false);
}
