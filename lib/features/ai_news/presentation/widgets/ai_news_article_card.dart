import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_hero_banner.dart' show aiNewsCategoryColor, aiNewsCategoryLabel;

/// AI 资讯列表卡片(非头版)。
class AiNewsArticleCard extends StatelessWidget {
  const AiNewsArticleCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final AiNewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = aiNewsCategoryColor(item.category);
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Body(item: item, accent: accent)),
              const SizedBox(width: AppSpacing.lg),
              _Cover(color: item.coverColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.accent});

  final AiNewsItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryStrip(
          category: item.category,
          accent: accent,
          source: item.source,
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Text(
          item.title,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          item.summary,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tag in item.tags.take(3)) _MiniTag(label: '#$tag'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Meta(item: item),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.category,
    required this.accent,
    required this.source,
  });

  final AiNewsCategory category;
  final Color accent;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            aiNewsCategoryLabel(category),
            style: AppTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          Icons.circle,
          size: 4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          source,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style:
            AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _relativeTime(item.publishedAt),
          style:
              AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(
          Icons.visibility_outlined,
          size: 12,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _formatCount(item.reads),
          style:
              AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(
          Icons.favorite_outline_rounded,
          size: 12,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _formatCount(item.likes),
          style:
              AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Icon(
          Icons.bookmark_outline_rounded,
          size: 16,
          color: colors.onSurfaceVariant,
        ),
      ],
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _relativeTime(DateTime t) {
    final now = DateTime(2026, 6, 25, 10, 0);
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.color});

  final int color;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
