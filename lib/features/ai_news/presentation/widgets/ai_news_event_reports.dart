import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/i18n/relative_time_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';

/*
*聚类报道的渐进展开入口；报道篇数与去重后的来源数分别表达。
*/
class AiNewsEventReports extends StatefulWidget {
  const AiNewsEventReports({required this.items, required this.onOpenReport, super.key});

  // 聚类成员按原有顺序保留。
  final List<AiNewsItem> items;

  // 每篇报道打开自己的缓存详情。
  final ValueChanged<AiNewsItem> onOpenReport;

  @override
  /* 展开状态仅属于当前列表事件。 */
  State<AiNewsEventReports> createState() => _AiNewsEventReportsState();
}

/*
*管理局部展开状态，列表通过事件 Key 保持排序后的身份。
*/
class _AiNewsEventReportsState extends State<AiNewsEventReports> {
  // 默认折叠，保持扫描密度。
  bool _expanded = false;

  @override
  /* 提供可键盘操作的展开按钮与逐篇报道入口。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final sourceCount = widget.items.map((item) => item.source.trim().toLowerCase()).where((source) => source.isNotEmpty).toSet().length;
    final label = l10n.tr('ai_news.event_reports').replaceAll('{reports}', '${widget.items.length}').replaceAll('{sources}', '$sourceCount');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          child: TextButton.icon(
            key: const ValueKey('ai-news-event-toggle'),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(label),
          ),
        ),
        if (_expanded) ...[
          Text(l10n.tr('ai_news.event_grouping_note'), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in widget.items) _ReportEntry(item: item, onTap: () => widget.onOpenReport(item)),
        ],
      ],
    );
  }
}

/*
*展开后保留完整标题与来源，点击范围不会触发主报道的外层按钮。
*/
class _ReportEntry extends StatelessWidget {
  const _ReportEntry({required this.item, required this.onTap});

  // 对应原始资讯，不能用主报道代替。
  final AiNewsItem item;
  final VoidCallback onTap;

  @override
  /* 展示报道元信息并进入应用内详情。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('ai-news-report-${item.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titleForLanguage(l10n.locale.languageCode), style: AppTypography.bodyMedium.copyWith(color: colors.onSurface)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${item.source} · ${formatRelativeTime(l10n, item.publishedAt)}', style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
