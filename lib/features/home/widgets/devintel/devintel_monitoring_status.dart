import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../monitor/application/monitor_providers.dart';

class DevIntelMonitoringStatus extends ConsumerWidget {
  const DevIntelMonitoringStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final repos = ref.watch(visibleMonitorDigestProvider).maybeWhen(data: (digest) => digest.monitoredRepos.take(4).toList(), orElse: () => const <RepoEntity>[]);
    return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.tr('home.monitoring.title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < repos.length; i++) ...[_StatusTile(repo: repos[i]), if (i != repos.length - 1) const SizedBox(height: AppSpacing.md)],
          const SizedBox(height: AppSpacing.lg),
          const _ConfigureButton()
        ]));
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.repo});

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(repo);
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(repo.fullName, style: AppTypography.titleSmall.copyWith(color: colors.onSurface), overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs))),
          child: Text(_status(l10n, repo), style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700, color: statusColor)),
        )
      ],
    );
  }

  String _status(AppLocalizations l10n, RepoEntity repo) {
    if (repo.starDelta >= 500) {
      return l10n.tr('devintel.status.active');
    }
    if (repo.starDelta >= 120) {
      return l10n.tr('devintel.status.syncing');
    }
    return l10n.tr('devintel.status.stable');
  }

  Color _statusColor(RepoEntity repo) {
    if (repo.starDelta >= 500) {
      return AppColors.warning;
    }
    if (repo.starDelta >= 120) {
      return AppColors.info;
    }
    return AppColors.success;
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
          side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md2),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm))),
        ),
        child: Text(l10n.tr('home.monitoring.configure'), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ),
    );
  }
}
