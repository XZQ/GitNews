import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/i18n/relative_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';

/*
*AI 动态列表条目 — 标题优先的安静排版。
*参照主流资讯产品(Apple News / Google News / 少数派)的共同范式:
*- 标题是第一视觉层级,不被徽章挤压、不被彩色标签抢戏
*- 摘要弱化为第二层级
*- 来源/分类/时间收进底部一行小字 meta;分类只用颜色点示意,不再用 pill
*- 精选与热度合并为行尾一个小元素;容器与今日 AI 日报统一使用 [AppCard]
*/
class AiNewsArticleCard extends StatelessWidget {
  const AiNewsArticleCard({
    required this.item,
    required this.onTap,
    this.eventSources = const [],
    super.key,
  });

  final AiNewsItem item;
  final VoidCallback onTap;
  final List<String> eventSources;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final accent = aiNewsCategoryColor(item.category);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs2),
            Text(
              item.summary,
              style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs2),
              Flexible(
                child: Text(
                  '${item.source} · ${item.category.label} · ${formatRelativeTime(l10n, item.publishedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              const Spacer(),
              if (item.selected) ...[
                const Icon(Icons.star_rounded, size: 13, color: AppColors.starGold),
                const SizedBox(width: AppSpacing.xxs),
              ],
              if (item.score > 0)
                Text(
                  '${item.score}',
                  style: AppTypography.labelSmall.copyWith(
                    color: item.selected ? AppColors.starGold : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (eventSources.length > 1) ...[
            const SizedBox(height: AppSpacing.xs2),
            _EventSources(sources: eventSources),
          ],
        ],
      ),
    );
  }
}

class _EventSources extends StatelessWidget {
  const _EventSources({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.hub_rounded, size: 12, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${l10n.tr('ai_news.event_sources').replaceAll('{count}', '${sources.length}')} · ${sources.join(' · ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(color: colors.primary),
          ),
        ),
      ],
    );
  }
}
