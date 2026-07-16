import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';

/*
*详情阅读流第三页:延伸要点、相关推荐和更多信息。
*/
class AiNewsDetailExtended extends StatelessWidget {
  const AiNewsDetailExtended({
    required this.item,
    required this.relatedItems,
    this.onOpenOriginal,
    this.onOpenRelated,
    this.onViewMore,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 来自本机缓存的相关推荐。
  final List<AiNewsItem> relatedItems;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  // 打开相关推荐操作。
  final ValueChanged<AiNewsItem>? onOpenRelated;

  // 返回资讯列表操作。
  final VoidCallback? onViewMore;

  @override
  /* 构建第三页延伸阅读内容。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AiNewsDetailPageFrame(
      scrollKey: const PageStorageKey('ai-news-detail-extended-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AiNewsDetailCategoryPill(category: item.category),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const AiNewsDetailPageMarker(current: 3, total: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailSectionTitle(
            icon: Icons.menu_book_outlined,
            title: l10n.tr('ai_news.detail.extended'),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExtendedPoint(
            title: l10n.tr('ai_news.detail.key_information'),
            body: item.summary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ExtendedPoint(
            title: l10n.tr('ai_news.detail.developer_impact'),
            body: l10n.tr('ai_news.detail.category_context'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ExtendedPoint(
            title: l10n.tr('ai_news.detail.attention_reason'),
            body: l10n.tr(
              item.selected ? 'ai_news.detail.selected_context' : 'ai_news.detail.score_context',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailSourceCard(item: item, onOpenOriginal: onOpenOriginal),
          if (relatedItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AiNewsDetailSectionTitle(
              icon: Icons.feed_outlined,
              title: l10n.tr('ai_news.detail.related_articles'),
              trailing: TextButton.icon(
                onPressed: onViewMore,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text(l10n.tr('ai_news.detail.view_more')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < relatedItems.length; index++) ...[
              _RelatedArticleCard(
                item: relatedItems[index],
                imageAsset: _relatedImage(index),
                onTap: () => onOpenRelated?.call(relatedItems[index]),
              ),
              if (index != relatedItems.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailSectionTitle(
            icon: Icons.info_outline_rounded,
            title: l10n.tr('ai_news.detail.more_info'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: AppColors.brandLight.withValues(
              alpha: Theme.of(context).brightness == Brightness.light ? 0.22 : 0.06,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: onOpenOriginal,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.24),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.source} · ${l10n.tr('ai_news.detail.view_original')}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* 按卡片顺序复用已登记的资讯插画资产。 */
  String _relatedImage(int index) {
    const assets = [
      'assets/ai_news/article_neural.png',
      'assets/ai_news/article_document.png',
      'assets/ai_news/article_city.png',
    ];
    return assets[index % assets.length];
  }
}

/*
*延伸解读的圆点要点。
*/
class _ExtendedPoint extends StatelessWidget {
  const _ExtendedPoint({required this.title, required this.body});

  // 要点标题。
  final String title;

  // 要点内容。
  final String body;

  @override
  /* 构建带品牌色圆点的文本要点。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.sm2,
          height: AppSpacing.sm2,
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          decoration: const BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.72,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/*
*相关推荐的紧凑卡片。
*/
class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({
    required this.item,
    required this.imageAsset,
    required this.onTap,
  });

  static const double _thumbnailSize = 64;

  // 推荐资讯。
  final AiNewsItem item;

  // 资讯缩略图资产。
  final String imageAsset;

  // 打开推荐资讯操作。
  final VoidCallback onTap;

  @override
  /* 构建相关资讯标题、摘要与分类。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  imageAsset,
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandLight.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  item.category.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right_rounded, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}
