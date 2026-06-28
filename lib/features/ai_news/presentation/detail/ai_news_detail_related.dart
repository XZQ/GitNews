import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/ai_news_item.dart';
import '../widgets/ai_news_hero_banner.dart'
    show aiNewsCategoryColor, aiNewsCategoryLabel;

class AiNewsDetailRelated extends StatelessWidget {
  const AiNewsDetailRelated({required this.items, super.key});

  final List<AiNewsItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '相关动态',
              subtitle: '其它热门 AI 资讯',
            ),
          ),
          for (final e in items) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              onTap: () => context.push('/ai_news/detail/${e.id}'),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      aiNewsCategoryColor(e.category).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: aiNewsCategoryColor(e.category),
                ),
              ),
              title: Text(
                e.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall,
              ),
              subtitle: Text(
                '${e.source} · ${aiNewsCategoryLabel(e.category)}',
                style: AppTypography.labelSmall,
              ),
              trailing: Text(
                '+${_shortNumber(e.likes)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}
