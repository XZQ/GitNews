import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/ai_news_item.dart';

class AiNewsDetailMeta extends StatelessWidget {
  const AiNewsDetailMeta({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _MetaTile(
            icon: Icons.source_outlined,
            label: '来源',
            value: item.source,
          ),
          _MetaTile(
            icon: Icons.person_outline,
            label: '作者',
            value: item.author,
          ),
          _MetaTile(
            icon: Icons.schedule_rounded,
            label: '阅读',
            value: '${item.readMinutes} 分钟',
          ),
          _MetaTile(
            icon: Icons.visibility_outlined,
            label: '阅读量',
            value: _shortNumber(item.reads),
          ),
          _MetaTile(
            icon: Icons.favorite_outline,
            label: '点赞',
            value: _shortNumber(item.likes),
            valueColor: colors.primary,
          ),
          _MetaTile(
            icon: Icons.event_outlined,
            label: '发布于',
            value: _formatDate(item.publishedAt),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label · ',
          style: AppTypography.labelMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: valueColor ?? colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}

String _formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
