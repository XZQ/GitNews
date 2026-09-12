import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/i18n/relative_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/ai_news_example_items.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';
import 'ai_news_event_reports.dart';

/*
*AI 动态列表条目。
*
*两端均以标题、摘要和来源为主，相关报道按需展开。
*/
class AiNewsArticleCard extends StatelessWidget {
  const AiNewsArticleCard({required this.item, required this.onTap, this.eventItems = const [], this.onOpenReport, this.isBookmarked = false, this.onBookmarkTap, super.key});

  // 资讯实体。
  final AiNewsItem item;

  // 打开资讯详情。
  final VoidCallback onTap;

  // 聚类成员仍逐篇可访问。
  final List<AiNewsItem> eventItems;
  final ValueChanged<AiNewsItem>? onOpenReport;

  // 当前条目是否已加入稍后读。
  final bool isBookmarked;

  // 切换稍后读状态;为空时仅展示状态图标。
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final reports = eventItems.length > 1 && onOpenReport != null ? AiNewsEventReports(items: eventItems, onOpenReport: onOpenReport!) : null;
    if (Breakpoints.isCompact(context)) {
      return _CompactArticleCard(item: item, onTap: onTap, isBookmarked: isBookmarked, onBookmarkTap: onBookmarkTap, reports: reports);
    }
    return _DesktopArticleCard(item: item, onTap: onTap, reports: reports);
  }
}

/*
*移动端资讯条目 — 纯文字三段式。
*
*结构为「来源行 / 标题 / 摘要」:来源行左起是分类色圆点 + 等宽来源名 +
*  分类标签,右端是相对时间与稍后读开关。
*不带缩略图,也不自带卡片外框:设计稿把同一天的条目收在一张卡里、用发丝
*  分隔线断行,外框与背景由 [AiNewsTimelineRow] 统一提供,这样连续多条
*  才能读成一张列表而不是一摞卡片。
*/
class _CompactArticleCard extends StatelessWidget {
  const _CompactArticleCard({required this.item, required this.onTap, required this.isBookmarked, required this.onBookmarkTap, required this.reports});

  // 资讯实体。
  final AiNewsItem item;

  // 打开详情。
  final VoidCallback onTap;

  // 是否已加入稍后读。
  final bool isBookmarked;

  // 切换稍后读状态。
  final VoidCallback? onBookmarkTap;

  // 可展开的全部相关报道。
  final Widget? reports;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final accent = aiNewsCategoryColor(item.category);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.source, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                      _CategoryChip(label: item.category.label, color: accent),
                      Text(isAiNewsExample(item) ? l10n.tr('ai_news.example') : formatRelativeTime(l10n, item.publishedAt), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.tr(isBookmarked ? 'ai_news.read_later_remove' : 'ai_news.read_later_add'),
                  onPressed: onBookmarkTap,
                  icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 17),
                  color: isBookmarked ? colors.primary : colors.onSurfaceVariant,
                  constraints: const BoxConstraints(minWidth: kMinInteractiveDimension, minHeight: kMinInteractiveDimension),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                item.titleForLanguage(l10n.locale.languageCode),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700, height: 1.35),
              ),
            ),
            if (item.summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs2),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  item.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                ),
              ),
            ],
            if (reports != null) ...[const SizedBox(height: AppSpacing.sm), reports!],
          ],
        ),
      ),
    );
  }
}

/*
*资讯分类标签 — 中性描边小药丸。
*
*设计稿用它区分「技巧 / 行业 / 产品」,颜色保持中性:分类的彩色信息已经由
*  左侧圆点承担,标签再上色会让来源行出现两处竞争的彩块。
*/
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  // 分类显示名。
  final String label;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/*
*桌面端标题优先资讯卡:保留原有扫描密度与多来源信息。
*/
class _DesktopArticleCard extends StatelessWidget {
  const _DesktopArticleCard({required this.item, required this.onTap, required this.reports});

  // 资讯实体。
  final AiNewsItem item;

  // 打开详情。
  final VoidCallback onTap;

  // 相关报道按需展开。
  final Widget? reports;

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
            item.titleForLanguage(l10n.locale.languageCode),
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs2),
            Text(
              item.summary,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              Text(
                '${item.source} · ${item.category.label} · ${isAiNewsExample(item) ? l10n.tr('ai_news.example') : formatRelativeTime(l10n, item.publishedAt)}',
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
              if (item.selected)
                Tooltip(
                  message: l10n.tr('ai_news.detail_selected'),
                  child: const Icon(Icons.star_rounded, size: 16, color: AppColors.starGold),
                ),
              if (item.score > 0 && !isAiNewsExample(item))
                Tooltip(
                  message: l10n.tr('ai_news.detail.score_context'),
                  child: Text('${l10n.tr('ai_news.source_score')} ${item.score}', style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                ),
            ],
          ),
          if (reports != null) ...[const SizedBox(height: AppSpacing.sm), reports!],
        ],
      ),
    );
  }
}
