import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/ai_news_item.dart';

class AiNewsDetailSummary extends StatelessWidget {
  const AiNewsDetailSummary({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '摘要', subtitle: '编辑整理的核心信息'),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class AiNewsDetailTags extends StatelessWidget {
  const AiNewsDetailTags({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '标签', subtitle: '相关话题与关键词'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in item.tags)
                Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
