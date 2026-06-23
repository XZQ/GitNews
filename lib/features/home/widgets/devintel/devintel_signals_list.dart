import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelSignalsList extends StatelessWidget {
  const DevIntelSignalsList({super.key});

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
          const Text(
            "Today's Developer Signals",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < kDevIntelSignals.length; i++) ...[
            _SignalTile(signal: kDevIntelSignals[i]),
            if (i != kDevIntelSignals.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final DevIntelSignal signal;

  @override
  Widget build(BuildContext context) {
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
                signal.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                signal.body,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
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
