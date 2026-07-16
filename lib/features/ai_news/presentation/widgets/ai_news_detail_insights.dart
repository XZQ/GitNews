import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import '../../domain/github_repo_link_extractor.dart';
import 'ai_news_detail_components.dart';
import 'ai_news_enrichment_card.dart';

/*
*详情阅读流第二页:AI 深度解读、背景和双语材料。
*/
class AiNewsDetailInsights extends StatelessWidget {
  const AiNewsDetailInsights({
    required this.item,
    required this.showEnrichment,
    this.onOpenOriginal,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 是否加载本地 AI 增强状态。
  final bool showEnrichment;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建第二页的深度阅读内容。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final originalText = item.titleEn.trim().isEmpty ? item.summary : item.titleEn;
    final repos = extractGitHubRepoLinks([
      item.title,
      item.titleEn,
      item.summary,
      item.url,
      item.permalink,
    ]);
    return AiNewsDetailPageFrame(
      scrollKey: const PageStorageKey('ai-news-detail-insights-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AiNewsDetailCategoryPill(category: item.category),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '·',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const AiNewsDetailPageMarker(current: 2, total: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showEnrichment) AiNewsEnrichmentCard(item: item) else _InsightPreview(item: item),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailSectionTitle(
            icon: Icons.article_outlined,
            title: l10n.tr('ai_news.detail.background'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.78,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.tr('ai_news.detail.category_context'),
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.78,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.tr(
              item.selected ? 'ai_news.detail.selected_context' : 'ai_news.detail.score_context',
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.78,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailLanguageCard(
            icon: Icons.translate_rounded,
            title: l10n.tr('ai_news.detail.original'),
            body: originalText,
            onOpenOriginal: onOpenOriginal,
          ),
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailLanguageCard(
            icon: Icons.g_translate_rounded,
            title: l10n.tr('ai_news.detail.translation'),
            body: item.summary,
            tinted: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tr('ai_news.detail.translation_note'),
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (repos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _RelatedTags(repos: repos),
          ],
        ],
      ),
    );
  }
}

/*
*测试与轻量嵌入场景使用的无状态解读预览。
*/
class _InsightPreview extends StatelessWidget {
  const _InsightPreview({required this.item});

  // 当前资讯。
  final AiNewsItem item;

  @override
  /* 构建不访问增强 Provider 的三段预览。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AiNewsDetailSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: l10n.tr('ai_news.detail.deep_read'),
          ),
          const SizedBox(height: AppSpacing.md),
          _PreviewRow(
            title: l10n.tr('ai_news.detail.core_view'),
            body: item.summary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PreviewRow(
            title: l10n.tr('ai_news.detail.why_it_matters'),
            body: l10n.tr('ai_news.detail.category_context'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PreviewRow(
            title: l10n.tr('ai_news.detail.use_cases'),
            body: '${item.category.label} · ${item.source}',
          ),
        ],
      ),
    );
  }
}

/*
*无状态解读预览中的单行内容。
*/
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.title, required this.body});

  // 标题。
  final String title;

  // 内容。
  final String body;

  @override
  /* 构建白底观点行。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/*
*从资讯正文识别出的 GitHub 仓库标签。
*/
class _RelatedTags extends StatelessWidget {
  const _RelatedTags({required this.repos});

  // 仓库全名列表。
  final List<String> repos;

  @override
  /* 构建可扫描的仓库标签行。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiNewsDetailSectionTitle(
          icon: Icons.sell_outlined,
          title: l10n.tr('ai_news.related_repos'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final repo in repos)
              Chip(
                avatar: const Icon(
                  Icons.code_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                label: Text(repo),
                side: BorderSide(
                  color: AppColors.brand.withValues(alpha: 0.28),
                ),
                backgroundColor: AppColors.brandLight.withValues(alpha: 0.2),
              ),
          ],
        ),
      ],
    );
  }
}
