import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';

/*
*详情页底部的相关文章列表。
*
*使用设计稿中的单卡分隔列表,避免连续大图卡片打断长文阅读。
*/
class AiNewsDetailExtended extends StatelessWidget {
  const AiNewsDetailExtended({
    required this.relatedItems,
    this.onOpenRelated,
    this.onViewMore,
    super.key,
  });

  // 来自本机缓存的相关推荐。
  final List<AiNewsItem> relatedItems;

  // 打开相关推荐操作。
  final ValueChanged<AiNewsItem>? onOpenRelated;

  // 返回资讯列表操作。
  final VoidCallback? onViewMore;

  @override
  /* 构建最多三条的紧凑相关文章卡片。 */
  Widget build(BuildContext context) {
    if (relatedItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final visibleItems = relatedItems.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tr('ai_news.detail.related_articles'),
                  style: AppTypography.reading(AppTypography.bodyLarge).copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewMore,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                label: Text(
                  l10n.tr('ai_news.detail.view_more'),
                  style: AppTypography.reading(
                    AppTypography.labelSmall,
                  ).copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < visibleItems.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: colors.outlineVariant,
                  ),
                _RelatedArticleRow(
                  item: visibleItems[index],
                  accent: _relatedAccent(index),
                  onTap: () => onOpenRelated?.call(visibleItems[index]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /* 按顺序为文字缩略块分配可复用语义色。 */
  Color _relatedAccent(int index) {
    const accents = [AppColors.accentPurple, AppColors.success, AppColors.info];
    return accents[index % accents.length];
  }
}

/*
*相关文章卡片中的单行摘要。
*/
class _RelatedArticleRow extends StatelessWidget {
  const _RelatedArticleRow({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  static const double _leadingSize = 44;

  // 推荐资讯。
  final AiNewsItem item;

  // 文字缩略块强调色。
  final Color accent;

  // 打开推荐资讯操作。
  final VoidCallback onTap;

  @override
  /* 构建文字缩略块、标题、摘要、分类和进入箭头。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = _relatedLabel(item.title);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: _leadingSize,
                height: _leadingSize,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTypography.titleLarge.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
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
                      style: AppTypography.reading(
                        AppTypography.titleSmall,
                      ).copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.reading(
                        AppTypography.bodySmall,
                      ).copyWith(color: aiNewsDetailSecondaryColor(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  item.category.label,
                  style: AppTypography.labelMicro.copyWith(
                    color: aiNewsDetailMutedColor(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: aiNewsDetailMutedColor(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* 优先取标题里的拉丁产品首字母,其次取中文引号短语的识别字。 */
  String _relatedLabel(String title) {
    final value = title.trim();
    if (value.isEmpty) {
      return 'AI';
    }
    final latin = RegExp(r'\b[A-Z]').firstMatch(value);
    if (latin != null) {
      return latin.group(0)!;
    }
    final quoted = RegExp(r'[「“"]([^」”"]+)').firstMatch(value)?.group(1);
    if (quoted != null && quoted.characters.length > 1) {
      return quoted.characters.elementAt(1);
    }
    return value.characters.first;
  }
}
