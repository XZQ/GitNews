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
*详情页中的 AI 深度解读与关联仓库区块。
*/
class AiNewsDetailInsights extends StatelessWidget {
  const AiNewsDetailInsights({
    required this.item,
    required this.showEnrichment,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 是否加载本地 AI 增强状态。
  final bool showEnrichment;

  @override
  /* 构建 AI 解读与正文中识别出的仓库标签。 */
  Widget build(BuildContext context) {
    final repos = extractGitHubRepoLinks([
      item.title,
      item.titleEn,
      item.summary,
      item.content,
      item.url,
      item.permalink,
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showEnrichment) AiNewsEnrichmentCard(item: item) else _InsightPreview(item: item),
        if (repos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _RelatedTags(repos: repos),
        ],
      ],
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
