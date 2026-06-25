import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'devintel_demo.dart';

class DevIntelRepoTable extends StatelessWidget {
  const DevIntelRepoTable({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '今日热门仓库',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HeaderRow(),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.outlineVariant, height: 1),
          for (var i = 0; i < kDevIntelRepoRows.length; i++) ...[
            if (i != 0) Divider(color: colors.outlineVariant, height: 1),
            _RepoRowTile(row: kDevIntelRepoRows[i]),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = AppTypography.labelSmall.copyWith(
      fontSize: 10,
      color: colors.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    return Row(
      children: [
        SizedBox(width: 32, child: Text('排名', style: style)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 5,
          child: Text('仓库', style: style),
        ),
        SizedBox(
          width: 100,
          child: Text('分类', style: style),
        ),
        SizedBox(
          width: 80,
          child: Text(
            '语言',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            '新增 Star',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            '总 Star',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _RepoRowTile extends StatelessWidget {
  const _RepoRowTile({required this.row});

  final DevIntelRepoRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(
        '/repo_detail/${Uri.encodeComponent(row.name)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: row.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  row.rank,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: row.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 5,
              child: Text(
                row.name,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13,
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: _CategoryBadge(text: row.category, color: row.color),
            ),
            SizedBox(
              width: 80,
              child: Text(
                row.lang,
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                row.newStars,
                textAlign: TextAlign.right,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                row.total,
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.xs + 2),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
