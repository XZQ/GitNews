import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/entities.dart';

/*
*趋势热榜仓库列表(含空态与加载遮罩)。
*从 trending_desktop_view 拆出,保持主视图文件 < 300 行(AGENTS.md)。
*/
class TrendingList extends StatelessWidget {
  const TrendingList({required this.repos, required this.isLoading, super.key});

  final List<RepoEntity> repos;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (repos.isEmpty) {
      return Stack(
        children: [
          AppCard(child: EmptyView(icon: Icons.search_off_rounded, message: l10n.tr('trending.list.empty'))),
          if (isLoading) _TrendingListLoadingOverlay(message: l10n.tr('trending.list.updating'))
        ],
      );
    }

    return Stack(children: [
      AppCard(
          padding: EdgeInsets.zero,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                child: SectionHeader(title: l10n.tr('trending.page.repos'), subtitle: l10n.tr('trending.list.subtitle.short')),
              ),
            ),
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
                sliver: SliverList.separated(
                    itemCount: repos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      return RepoTile(repo: repos[i], rank: i + 1, onTap: () => context.go('/trending/detail/${Uri.encodeComponent(repos[i].fullName)}'));
                    }))
          ])),
      if (isLoading) _TrendingListLoadingOverlay(message: l10n.tr('trending.list.updating'))
    ]);
  }
}

class _TrendingListLoadingOverlay extends StatelessWidget {
  const _TrendingListLoadingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.72)),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.8)),
                boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: AppSpacing.sm), Text(message)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
