import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'devintel_demo.dart';

class DevIntelMonitoringStatus extends StatelessWidget {
  const DevIntelMonitoringStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.tr('home.monitoring.title'),
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurface,
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
    final colors = Theme.of(context).colorScheme;
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
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            item.name,
            style: AppTypography.titleSmall.copyWith(
              color: colors.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: item.statusColor.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.xs),
            ),
          ),
          child: Text(
            item.status,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: item.statusColor,
            ),
          ),
        ),
        if (item.note != null) ...[
          const SizedBox(width: AppSpacing.xs2),
          Text(
            item.note!,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.go('/monitor/settings'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: BorderSide(
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md2),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
        child: Text(
          l10n.tr('home.monitoring.configure'),
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
