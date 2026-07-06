import 'package:flutter/material.dart';

import '../../core/domain/data_provenance.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class DataProvenanceBadge extends StatelessWidget {
  const DataProvenanceBadge({
    required this.provenance,
    this.compact = true,
    this.inverse = false,
    super.key,
  });

  final DataProvenance provenance;
  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final label = compact ? _shortLabel : provenance.zhLabel;
    return Tooltip(
      message: _tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs2 : AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: inverse
              ? Colors.white.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.1),
          border: Border.all(
            color: inverse
                ? Colors.white.withValues(alpha: 0.28)
                : color.withValues(alpha: 0.28),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.labelMicro.copyWith(
            color: inverse ? Colors.white : color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  String get _shortLabel {
    return switch (provenance) {
      DataProvenance.observed => '观测',
      DataProvenance.estimated => '估算',
      DataProvenance.localFallback => '兜底',
    };
  }

  String get _tooltip {
    return switch (provenance) {
      DataProvenance.observed => '来自 GitHub API 或本地跨天快照',
      DataProvenance.estimated => '根据当前观测值推导,不是完整历史',
      DataProvenance.localFallback => '远端不可用或首次启动时的本地兜底数据',
    };
  }

  Color _color(BuildContext context) {
    return switch (provenance) {
      DataProvenance.observed => AppColors.success,
      DataProvenance.estimated => AppColors.warning,
      DataProvenance.localFallback => Theme.of(context).colorScheme.outline,
    };
  }
}
