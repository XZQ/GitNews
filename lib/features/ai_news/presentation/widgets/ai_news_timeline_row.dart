import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_article_card.dart';
import 'ai_news_category_style.dart';

/* 
*单条时间线行:左列时间 + 圆点 + 竖线,右列卡片。
*/
class AiNewsTimelineRow extends StatelessWidget {
  const AiNewsTimelineRow({required this.item, required this.onTap, super.key});

  final AiNewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dotColor = item.selected ? AppColors.starGold : aiNewsCategoryColor(item.category);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: colors.outlineVariant.withValues(
                      alpha: isLight ? 0.6 : 1,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: AppSpacing.lg,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md + 5,
                  left: 0,
                  right: 14,
                  child: Text(
                    _hhmm(item.publishedAt.toLocal()),
                    textAlign: TextAlign.right,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: AiNewsArticleCard(item: item, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
