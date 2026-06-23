import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A30)),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(spec.icon, size: 16, color: spec.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spec.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 10,
            color: AppColors.success,
          ),
          const SizedBox(width: 2),
          Text(
            delta,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
