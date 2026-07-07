import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

// 注:卡片自身不带外边框/表面色/圆角 —— 这些由外层 [BorderedRow] 统一提供。

/// 首页"栏目预览卡":统一渲染 标题 / 列表 / 跳转。
///
/// 用于 AI 动态 / GitHub热榜 / 技术趋势 三栏 Top N 预览。
class HomeSectionPreviewCard<T> extends StatelessWidget {
  const HomeSectionPreviewCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.path,
    required this.items,
    required this.tileBuilder,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String path;
  final List<T> items;
  final Widget Function(BuildContext, T, int) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.xl2,
                height: AppSpacing.xl2,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: AppSpacing.md2, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _MoreChip(path: path, accentColor: accentColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0) const SizedBox(height: AppSpacing.sm),
            tileBuilder(context, items[i], i),
          ],
        ],
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.path, required this.accentColor});

  final String path;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm2,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.tr('common.more'),
                style: AppTypography.labelSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSpacing.md,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 预览行通用样式:rank + 标题 + 副信息。
class PreviewRow extends StatelessWidget {
  const PreviewRow({
    required this.rank,
    required this.rankColor,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    super.key,
  });

  final String rank;
  final Color rankColor;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: Text(
                  rank,
                  style: AppTypography.labelSmall.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                meta,
                style: AppTypography.labelSmall.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
