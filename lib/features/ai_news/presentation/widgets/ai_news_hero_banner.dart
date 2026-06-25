import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';

/// AI 资讯头版大图卡片(置顶 + isHero)。
class AiNewsHeroBanner extends StatelessWidget {
  const AiNewsHeroBanner({
    required this.item,
    required this.categoryLabel,
    required this.onTap,
    super.key,
  });

  final AiNewsItem item;
  final String categoryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(item.coverColor);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.95),
                Color.lerp(accent, Colors.black, 0.35)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -40,
                top: -40,
                child: Opacity(
                  opacity: 0.18,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 220,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBadge(label: '头版 · $categoryLabel'),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      item.title,
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.summary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final tag in item.tags.take(4))
                          _HeroTag(label: '#$tag'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _HeroMeta(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.article_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          item.source,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(
          Icons.schedule_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${item.readMinutes} 分钟',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.favorite_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _formatCount(item.likes),
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// 把分类枚举映射到中文标签。
String aiNewsCategoryLabel(AiNewsCategory c) {
  switch (c) {
    case AiNewsCategory.industry:
      return '行业动态';
    case AiNewsCategory.breakthrough:
      return '技术突破';
    case AiNewsCategory.application:
      return '产业应用';
    case AiNewsCategory.funding:
      return '投融资';
  }
}

/// 用于主题色亮色徽章,分类 → 颜色 token。
Color aiNewsCategoryColor(AiNewsCategory c) {
  switch (c) {
    case AiNewsCategory.industry:
      return AppColors.info;
    case AiNewsCategory.breakthrough:
      return AppColors.brand;
    case AiNewsCategory.application:
      return AppColors.success;
    case AiNewsCategory.funding:
      return AppColors.warning;
  }
}
