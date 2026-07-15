import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DiscoverProfileMetricPill extends StatelessWidget {
  const DiscoverProfileMetricPill({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DiscoverProfileIconMetric extends StatelessWidget {
  const DiscoverProfileIconMetric({
    required this.icon,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(value, style: AppTypography.labelSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600))
      ],
    );
  }
}

String shortNumber(int value) => switch (value) { >= 1000000 => '${(value / 1000000).toStringAsFixed(1)}M', >= 1000 => '${(value / 1000).toStringAsFixed(1)}k', _ => value.toString() };

String placeholderOrNumber(int value, bool enriched) => enriched ? shortNumber(value) : '—';
