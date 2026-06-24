import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelSignalsList extends StatelessWidget {
  const DevIntelSignalsList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
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
          Text(
            t.t('devintel.signalsTitle'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < kDevIntelSignals.length; i++) ...[
            _SignalTile(signal: kDevIntelSignals[i], t: t),
            if (i != kDevIntelSignals.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal, required this.t});

  final DevIntelSignal signal;
  final AppStrings t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: signal.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.t(signal.titleKey),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.t(signal.bodyKey),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
