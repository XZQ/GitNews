import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_star_change.dart';

/*
*热门仓库 — 单卡内嵌三行榜单。
*
*设计稿把前三名收在一张卡里、行间用细分隔线,而不是三张各自带边框的
*  卡片:窄屏上连续的独立卡片会产生三条外框 + 三段留白,视觉噪声压过
*  内容本身。行内用 `card: false` 的 [RepoTile] 复用统一的仓库行结构。
*/
class HomeMobileHotReposCard extends StatelessWidget {
  const HomeMobileHotReposCard({required this.repos, required this.title, required this.meta, required this.emptyMessage, super.key});

  // 榜单前三名;为空时整卡退化为空状态。
  final List<RepoEntity> repos;

  // 卡片标题(如「热门仓库」)。
  final String title;

  // 标题右侧的等宽口径说明(如「今日 · 3 个项目」)。
  final String meta;

  // 无数据时展示的文案。
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: repos.isEmpty
              ? EmptyView(icon: Icons.local_fire_department_outlined, message: emptyMessage)
              : Column(
                  children: [
                    for (var index = 0; index < repos.length; index++) ...[
                      if (index != 0) Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: colors.outlineVariant),
                      _HotRepoRow(repo: repos[index], rank: index + 1, onTap: () => context.push('/trending/detail/${Uri.encodeComponent(repos[index].fullName)}')),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/* 热门仓库分组卡片中的紧凑排行榜行。 */
class _HotRepoRow extends StatelessWidget {
  const _HotRepoRow({required this.repo, required this.rank, required this.onTap});

  final RepoEntity repo;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(repo.accentArgb);
    final repoName = repo.fullName.split('/').last;
    final initial = repoName.isEmpty ? '?' : repoName.characters.first.toUpperCase();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.lg,
              child: Text(
                '$rank',
                style: AppTypography.monoMeta.copyWith(color: rank == 1 ? AppColors.warning : colors.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.titleSmall.copyWith(color: accent, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoTitle.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.xs2,
                        height: AppSpacing.xs2,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.xs2),
                      Flexible(
                        child: Text(
                          repo.language,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.starGold),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(_shortNumber(repo.starCount), style: AppTypography.monoMeta.copyWith(color: AppColors.starGold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            RepoStarChange(repo: repo),
          ],
        ),
      ),
    );
  }
}

/* 把仓库指标压缩为移动端短数字。 */
String _shortNumber(int value) {
  final absolute = value.abs();
  final sign = value < 0 ? '-' : '';
  if (absolute >= 1000000) {
    return '$sign${(absolute / 1000000).toStringAsFixed(1)}M';
  }
  if (absolute >= 1000) {
    return '$sign${(absolute / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
