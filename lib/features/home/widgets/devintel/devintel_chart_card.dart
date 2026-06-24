import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/star_trend_chart.dart';
import 'devintel_demo.dart';

class DevIntelChartCard extends StatefulWidget {
  const DevIntelChartCard({super.key});

  @override
  State<DevIntelChartCard> createState() => _DevIntelChartCardState();
}

class _DevIntelChartCardState extends State<DevIntelChartCard> {
  int _window = 30;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final values =
        _window == 7 ? kDevIntelChartValues7 : kDevIntelChartValues30;
    final series = <ChartSeries>[
      ChartSeries(
        values: values,
        color: AppColors.success.withValues(alpha: 0.35),
      ),
      ChartSeries(
        values: values.map((v) => v + 1500).toList(),
        color: AppColors.success,
      ),
    ];
    final labels =
        kDevIntelXLabels.map((key) => key.isEmpty ? '' : t.t(key)).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.t('devintel.chartTitle'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.t('devintel.chartSubtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _WindowSegment(
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 240,
            child: StarTrendChart(
              series: series,
              xLabels: labels,
              height: 240,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowSegment extends StatelessWidget {
  const _WindowSegment({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(t.t('devintel.window7d'))),
        ButtonSegment(value: 30, label: Text(t.t('devintel.window30d'))),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : colors.surfaceContainerHighest,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colors.onSurfaceVariant,
        ),
        side: WidgetStateProperty.all(BorderSide.none),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
      ),
    );
  }
}
