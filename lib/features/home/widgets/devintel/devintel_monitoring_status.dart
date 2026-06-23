import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelMonitoringStatus extends StatelessWidget {
  const DevIntelMonitoringStatus({super.key});

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
            'Repository Monitoring Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < kDevIntelMonitoring.length; i++) ...[
            _StatusTile(item: kDevIntelMonitoring[i]),
            if (i != kDevIntelMonitoring.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _ConfigureButton(),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.item});

  final DevIntelMonitoring item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: item.statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.statusColor,
            ),
          ),
        ),
        if (item.note != null) ...[
          const SizedBox(width: 6),
          Text(
            item.note!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfigureButton extends StatelessWidget {
  const _ConfigureButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.go('/monitor/settings'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: BorderSide(
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'CONFIGURE WATCHLIST',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
