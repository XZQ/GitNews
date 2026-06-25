import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'devintel_demo.dart';

class DevIntelMetricStrip extends StatelessWidget {
  const DevIntelMetricStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricTile(spec: kDevIntelMetrics[0])),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _MetricTile(spec: kDevIntelMetrics[1])),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _MetricTile(spec: kDevIntelMetrics[2])),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _MetricTile(spec: kDevIntelMetrics[3])),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.spec});

  final DevIntelMetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.lg)),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSpacing.sm),
                  ),
                ),
                child: Icon(spec.icon, size: 16, color: spec.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  spec.title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spec.value,
                style: AppTypography.displayMedium.copyWith(
                  color: colors.onSurface,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              _DeltaPill(delta: spec.delta),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});

  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 10,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            delta,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
