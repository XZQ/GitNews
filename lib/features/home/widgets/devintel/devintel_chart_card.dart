import 'package:flutter/material.dart';

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Star Growth Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Aggregated growth across monitored repositories',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
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
              xLabels: kDevIntelXLabels,
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
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7 Days')),
        ButtonSegment(value: 30, label: Text('30 Days')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : const Color(0xFF1F1F25),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textSecondaryDark,
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
