import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';

/* 
*AI 动态列表卡片。
*/
class AiNewsArticleCard extends StatelessWidget {
  const AiNewsArticleCard({required this.item, required this.onTap, super.key});

  final AiNewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = aiNewsCategoryColor(item.category);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1), width: 1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryStrip(category: item.category, accent: accent, source: item.source),
              const SizedBox(height: AppSpacing.sm2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.selected) ...[const SizedBox(width: AppSpacing.sm), const _SelectedPill()],
                  const SizedBox(width: AppSpacing.sm),
                  _ScorePill(score: item.score)
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.summary,
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant, height: 1.55),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              _Meta(publishedAt: item.publishedAt)
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.category, required this.accent, required this.source});

  final AiNewsCategory category;
  final Color accent;
  final String source;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(category.label, style: AppTypography.labelSmall.copyWith(color: accent, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.circle, size: 4, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
            child: Text(
          source,
          style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ))
      ],
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: AppColors.starGold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.starGold),
          const SizedBox(width: AppSpacing.xxs),
          Text('精选', style: AppTypography.labelSmall.copyWith(color: AppColors.starGold, fontWeight: FontWeight.w700))
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: AppColors.brandCyanLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text('$score', style: AppTypography.labelSmall.copyWith(color: AppColors.brand, fontWeight: FontWeight.w700)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.publishedAt});

  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(_relativeTime(publishedAt), style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))
      ],
    );
  }

  static String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} 天前';
    }
    return '${t.month}/${t.day}';
  }
}
