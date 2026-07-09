import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/star_trend_chart.dart';
import '../../../trending/application/trending_providers.dart';

class DevIntelChartCard extends ConsumerStatefulWidget {
  const DevIntelChartCard({super.key});

  @override
  ConsumerState<DevIntelChartCard> createState() => _DevIntelChartCardState();
}

class _DevIntelChartCardState extends ConsumerState<DevIntelChartCard> {
  int _window = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final digest = ref.watch(trendingDigestProvider).valueOrNull;
    final primary = _sliceWindow(digest?.primaryTrend ?? const <double>[]);
    final secondary = _sliceWindow(digest?.secondaryTrend ?? const <double>[]);
    final series = <ChartSeries>[
      ChartSeries(
        values: secondary.isEmpty ? primary : secondary,
        color: AppColors.success.withValues(alpha: 0.35),
      ),
      ChartSeries(values: primary, color: AppColors.success),
    ];
    final labels = _labels(l10n, primary.length);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1),
          width: 1,
        ),
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
                      l10n.tr('home.chart.title'),
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.tr('home.chart.subtitle'),
                      style: AppTypography.bodySmall.copyWith(
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
            child: StarTrendChart(series: series, xLabels: labels, height: 240),
          ),
        ],
      ),
    );
  }

  List<double> _sliceWindow(List<double> values) {
    if (values.isEmpty) {
      return const [0, 0, 0, 0, 0, 0, 0];
    }
    final target = _window == 7 ? 7 : values.length;
    if (values.length <= target) {
      return values;
    }
    return values.sublist(values.length - target);
  }

  List<String> _labels(AppLocalizations l10n, int count) {
    if (count <= 0) {
      return const [];
    }
    if (_window == 7) {
      return [
        l10n.tr('devintel.chart.label.mon'),
        '',
        l10n.tr('devintel.chart.label.wed'),
        '',
        l10n.tr('devintel.chart.label.fri'),
        '',
        l10n.tr('common.today'),
      ];
    }
    return List<String>.generate(count, (index) {
      if (index == 0) {
        return l10n.tr('devintel.chart.label.start');
      }
      if (index == count - 1) {
        return l10n.tr('common.today');
      }
      return index % 4 == 0 ? '+$index' : '';
    });
  }
}

class _WindowSegment extends StatelessWidget {
  const _WindowSegment({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(l10n.tr('home.chart.window_7'))),
        ButtonSegment(value: 30, label: Text(l10n.tr('home.chart.window_30'))),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.success : colors.surfaceContainerHighest,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : colors.onSurfaceVariant,
        ),
        side: WidgetStateProperty.all(BorderSide.none),
        textStyle: WidgetStateProperty.all(
          AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md2,
            vertical: AppSpacing.xs2,
          ),
        ),
      ),
    );
  }
}
