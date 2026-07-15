import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';

/*
*二级页 3:热门仓库(完整列表 + 表格视图)。
*/
class HotReposPage extends ConsumerWidget {
  const HotReposPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(filteredTrendingDigestProvider);
    final searchQuery = ref.watch(trendingSearchQueryProvider).trim();
    return Scaffold(
        appBar: AppBar(title: Text(l10n.tr('trending.hot_repos.title')), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/trending'))),
        body: state.when(
            data: (digest) {
              if (digest.allRepos.isEmpty) {
                return EmptyView(
                  icon: searchQuery.isEmpty ? Icons.local_fire_department_outlined : Icons.search_off_rounded,
                  message: searchQuery.isEmpty ? l10n.tr('trending.hot_repos.empty') : l10n.tr('trending.hot_repos.empty_search').replaceAll('{query}', searchQuery),
                );
              }
              return ResponsiveLayout(
                compact: (_) => _Body(digest: digest),
                medium: (_) => CenteredContent(child: _Body(digest: digest)),
                expanded: (_) => CenteredContent(child: _Body(digest: digest)),
              );
            },
            loading: () => const _PageSkeleton(),
            error: (error, stackTrace) => ErrorView(
                error: AppException(
                  kind: AppExceptionKind.unknown,
                  cause: error,
                  stack: stackTrace,
                ),
                onRetry: () => ref.invalidate(trendingDigestProvider))));
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.digest});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos = digest.allRepos;
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount: repos.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(title: l10n.tr('trending.hot_repos.list_title'), subtitle: l10n.tr('trending.hot_repos.list_subtitle').replaceAll('{count}', '${repos.length}')),
            );
          }
          if (index == repos.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: l10n.tr('trending.hot_repos.notes_title'), subtitle: l10n.tr('trending.hot_repos.notes_subtitle')),
                    const SizedBox(height: AppSpacing.sm),
                    _Bullet(l10n.tr('trending.hot_repos.note1')),
                    _Bullet(l10n.tr('trending.hot_repos.note2')),
                    _Bullet(l10n.tr('trending.hot_repos.note3'))
                  ],
                ),
              ),
            );
          }
          final i = index - 1;
          final repo = repos[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RepaintBoundary(
              // RepoTile 自带统一卡片样式,这里不再叠一层 AppCard。
              child: RepoTile(repo: repo, rank: i + 1, onTap: () => context.go('/trending/detail/${Uri.encodeComponent(repo.fullName)}')),
            ),
          );
        });
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs2, right: AppSpacing.sm),
            child: Container(
              width: AppSpacing.xs2,
              height: AppSpacing.xs2,
              decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(AppRadius.bar)),
            ),
          ),
          Expanded(child: Text(text, style: AppTypography.bodyMedium))
        ],
      ),
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Column(children: [Skeleton(height: 280), SizedBox(height: AppSpacing.lg), Skeleton(height: 120)]));
  }
}
