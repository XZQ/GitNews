import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_enrichment.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';
import 'ai_news_detail_language_content.dart';
import 'ai_news_detail_language_switcher.dart';

/*
*详情页顶部阅读区。
*
*严格按设计稿编排元数据、重标题、双语正文、状态指标和原始来源。
*/
class AiNewsDetailOverview extends StatelessWidget {
  const AiNewsDetailOverview({required this.item, this.enrichment, this.onOpenOriginal, super.key});

  // 当前资讯。
  final AiNewsItem item;

  // 已缓存的本地 AI 增强结果。
  final AiNewsEnrichment? enrichment;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建设计稿中的连续阅读首屏。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final languageContent = AiNewsDetailLanguageContent.fromItem(item, enrichment: enrichment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm2,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AiNewsDetailCategoryPill(category: item.category),
            Text('${formatAiNewsDetailDate(item.publishedAt)} · ${item.source}', style: AppTypography.mono(AppTypography.bodySmall).copyWith(color: aiNewsDetailMutedColor(context))),
            if (item.author.trim().isNotEmpty && item.author.trim() != item.source.trim())
              Text(item.author, style: AppTypography.mono(AppTypography.bodySmall).copyWith(color: aiNewsDetailMutedColor(context))),
          ],
        ),
        const SizedBox(height: AppSpacing.md2),
        Text(
          item.titleForLanguage(l10n.locale.languageCode),
          style: AppTypography.reading(AppTypography.displayMedium).copyWith(fontSize: 26, fontWeight: FontWeight.w800, height: 1.34, letterSpacing: -0.26, color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (languageContent.isEnglishArticle && languageContent.englishOriginal != null)
          AiNewsDetailLanguageSwitcher(englishOriginal: languageContent.englishOriginal!, chineseTranslation: languageContent.chineseTranslation)
        else
          _SingleLanguageBody(body: item.summary),
        if (item.content.trim().isNotEmpty && item.content.trim() != item.summary.trim()) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.tr('ai_news.detail.source_content'), style: AppTypography.reading(AppTypography.labelMicro).copyWith(color: aiNewsDetailMutedColor(context))),
          const SizedBox(height: AppSpacing.lg),
          Text(
            item.content,
            style: AppTypography.reading(AppTypography.bodyLarge).copyWith(fontSize: AppTypography.titleMedium.fontSize, height: 1.9, color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('// ${l10n.tr('ai_news.detail.source_content_note')}', style: AppTypography.reading(AppTypography.labelSmall).copyWith(color: aiNewsDetailMutedColor(context))),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm2,
          runSpacing: AppSpacing.sm,
          children: [
            AiNewsDetailMetricPill(icon: Icons.local_fire_department_rounded, label: '${l10n.tr('ai_news.detail_score')} ${item.score}'),
            if (item.selected) AiNewsDetailMetricPill(icon: Icons.check_circle_outline_rounded, label: l10n.tr('ai_news.detail_selected'), positive: true),
            if (item.attributionSource.isNotEmpty) AiNewsDetailMetricPill(icon: Icons.verified_outlined, label: item.attributionSource),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AiNewsDetailSourceCard(item: item, onOpenOriginal: onOpenOriginal),
      ],
    );
  }
}

/*
*中文资讯使用的单语正文区。
*/
class _SingleLanguageBody extends StatelessWidget {
  const _SingleLanguageBody({required this.body});

  // 正文摘要。
  final String body;

  @override
  /* 构建无重复语种卡片的中文阅读区。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tr('ai_news.detail.body'), style: AppTypography.reading(AppTypography.labelMicro).copyWith(color: aiNewsDetailMutedColor(context))),
        const SizedBox(height: AppSpacing.lg),
        Text(
          body,
          style: AppTypography.reading(AppTypography.bodyLarge).copyWith(fontSize: AppTypography.titleMedium.fontSize, height: 1.9, color: colors.onSurface),
        ),
      ],
    );
  }
}
