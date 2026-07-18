import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_enrichment.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';
import 'ai_news_detail_language_content.dart';

/*
*详情页顶部概览:标题、摘要、双语内容与来源。
*/
class AiNewsDetailOverview extends StatelessWidget {
  const AiNewsDetailOverview({
    required this.item,
    this.enrichment,
    this.onOpenOriginal,
    super.key,
  });

  static const double _wideHeroBreakpoint = 760;
  static const double _wideHeroWidth = 340;
  static const double _compactHeroHeight = 165;
  static const double _compactHeroWidth = 196;

  // 当前资讯。
  final AiNewsItem item;

  // 已缓存的本地 AI 增强结果。
  final AiNewsEnrichment? enrichment;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建详情页顶部概览内容。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final languageContent = AiNewsDetailLanguageContent.fromItem(
      item,
      enrichment: enrichment,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AiNewsDetailCategoryPill(category: item.category),
            Text(
              formatAiNewsDetailDate(item.publishedAt),
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              item.source,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _wideHeroBreakpoint) {
              return _CompactHero(
                item: item,
                height: constraints.maxWidth < 410 ? _compactHeroHeight : 145,
              );
            }
            return _WideHero(item: item);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!languageContent.isEnglishArticle && item.summary.trim().isNotEmpty)
          Text(
            item.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.76,
            ),
          ),
        if (languageContent.englishOriginal != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailLanguageCard(
            icon: Icons.translate_rounded,
            title: l10n.tr('ai_news.detail.original'),
            body: languageContent.englishOriginal!,
            onOpenOriginal: onOpenOriginal,
          ),
        ],
        if (languageContent.isEnglishArticle) ...[
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailLanguageCard(
            icon: Icons.g_translate_rounded,
            title: l10n.tr('ai_news.detail.translation'),
            body: languageContent.chineseTranslation ?? l10n.tr('ai_news.detail.translation_unavailable'),
            tinted: true,
          ),
          if (languageContent.chineseTranslation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.tr('ai_news.detail.translation_note'),
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AiNewsDetailMetricPill(
              icon: Icons.local_fire_department_rounded,
              label: '${l10n.tr('ai_news.detail_score')} ${item.score}',
            ),
            if (item.selected)
              AiNewsDetailMetricPill(
                icon: Icons.verified_rounded,
                label: l10n.tr('ai_news.detail_selected'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AiNewsDetailSourceCard(item: item, onOpenOriginal: onOpenOriginal),
      ],
    );
  }
}

/*
*宽窗口标题与主视觉并排布局。
*/
class _WideHero extends StatelessWidget {
  const _WideHero({required this.item});

  // 当前资讯。
  final AiNewsItem item;

  @override
  /* 构建桌面并排标题区。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final englishOriginal = AiNewsDetailLanguageContent.fromItem(item).englishOriginal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTypography.displayLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.26,
                ),
              ),
              if (englishOriginal != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  englishOriginal,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Semantics(
          image: true,
          label: 'AI memory synchronization illustration',
          child: Image.asset(
            'assets/ai_news/detail_memory_sync_hero.png',
            width: AiNewsDetailOverview._wideHeroWidth,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

/*
*紧凑窗口标题与主视觉叠放布局。
*/
class _CompactHero extends StatelessWidget {
  const _CompactHero({required this.item, required this.height});

  // 当前资讯。
  final AiNewsItem item;

  // 当前紧凑宽度下的标题区高度。
  final double height;

  @override
  /* 构建接近参考截图的紧凑标题区。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIllustration = item.title.length < 54;
          final titleWidth = showIllustration ? (constraints.maxWidth - 118).clamp(248.0, constraints.maxWidth).toDouble() : constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (showIllustration)
                Positioned(
                  right: -AppSpacing.md,
                  top: -AppSpacing.lg,
                  child: Semantics(
                    image: true,
                    label: 'AI memory synchronization illustration',
                    child: Image.asset(
                      'assets/ai_news/detail_memory_sync_hero.png',
                      width: AiNewsDetailOverview._compactHeroWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: SizedBox(
                  width: titleWidth,
                  child: Text(
                    item.title,
                    style: AppTypography.displayMedium.copyWith(
                      color: colors.onSurface,
                      fontSize: showIllustration ? 26 : 23,
                      fontWeight: FontWeight.w800,
                      height: 1.26,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
