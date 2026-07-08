import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/* 7 / 14 / 30 天窗口切换。 */
class ChartWindowSegmented extends StatelessWidget {
  const ChartWindowSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(l10n.tr('home.chart.window.7d'))),
        ButtonSegment(value: 14, label: Text(l10n.tr('home.chart.window.14d'))),
        ButtonSegment(value: 30, label: Text(l10n.tr('home.chart.window.30d'))),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class HomeLegendDot extends StatelessWidget {
  const HomeLegendDot({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.dot),
          ),
        ),
        const SizedBox(width: AppSpacing.xs2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
