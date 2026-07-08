import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    if (repos.isEmpty) {
      return Stack(
        children: [
          const AppCard(
            child: EmptyView(
              icon: Icons.search_off_rounded,
              message: '没有匹配的热门仓库',
            ),
          ),
          if (isLoading) const _TrendingListLoadingOverlay(),
        ],
      );
    }

    return Stack(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: SectionHeader(title: '热门仓库', subtitle: '按 Star 增速排序'),
                ),
              ),
              SliverList.builder(
                itemCount: repos.length,
                itemBuilder: (context, i) {
                  return Column(
                    children: [
                      if (i != 0) const Divider(height: 1),
                      RepoTile(
                        repo: repos[i],
                        onTap: () => context.go(
                          '/trending/detail/${Uri.encodeComponent(repos[i].fullName)}',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (isLoading) const _TrendingListLoadingOverlay(),
      ],
    );
  }
}

class _TrendingListLoadingOverlay extends StatelessWidget {
  const _TrendingListLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.72),
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('正在更新热榜'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
