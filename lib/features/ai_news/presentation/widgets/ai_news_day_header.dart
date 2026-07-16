import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';

/* 
*一天分组头:`今天 / 昨天 / M月d日` + 条目数。
*/
class AiNewsDayHeader extends StatelessWidget {
  const AiNewsDayHeader({required this.date, required this.itemCount, super.key});

  final DateTime date;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final String label;
    if (date == today) {
      label = l10n.tr('common.today');
    } else if (date == yesterday) {
      label = l10n.tr('ai_news.yesterday');
    } else {
      label = l10n.tr('ai_news.date_md').replaceAll('{m}', '${date.month}').replaceAll('{d}', '${date.day}');
    }

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? AppSpacing.sm : AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(width: AppRadius.bar, height: 14, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(AppRadius.xs))),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.xs2),
          Text('$itemCount ${l10n.tr('ai_news.day_count_suffix')}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
          if (isCompact) ...[
            const Spacer(),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(Icons.format_list_bulleted_rounded, size: 19, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
