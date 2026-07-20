import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/ai_news_item.dart';
import '../../domain/github_repo_link_extractor.dart';
import 'ai_news_detail_components.dart';
import 'ai_news_enrichment_card.dart';

/*
*详情页中的 AI 深度解读与关联仓库区块。
*/
class AiNewsDetailInsights extends StatelessWidget {
  const AiNewsDetailInsights({required this.item, required this.showEnrichment, super.key});

  // 当前资讯。
  final AiNewsItem item;

  // 是否加载本地 AI 增强状态。
  final bool showEnrichment;

  @override
  /* 构建 AI 解读与正文中识别出的仓库标签。 */
  Widget build(BuildContext context) {
    final repos = extractGitHubRepoLinks([item.title, item.titleEn, item.summary, item.content, item.url, item.permalink]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showEnrichment) AiNewsEnrichmentCard(item: item),
        if (repos.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), _RelatedTags(repos: repos)],
      ],
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
        AiNewsDetailSectionTitle(icon: Icons.sell_outlined, title: l10n.tr('ai_news.related_repos')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final repo in repos)
              Chip(
                avatar: const Icon(Icons.code_rounded, size: 16, color: AppColors.brand),
                label: Text(repo),
                side: BorderSide(color: AppColors.brand.withValues(alpha: 0.28)),
                backgroundColor: AppColors.brandLight.withValues(alpha: 0.2),
              ),
          ],
        ),
      ],
    );
  }
}
