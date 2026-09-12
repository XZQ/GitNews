import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_check_status.dart';
import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/repo_check_status_view.dart';
import '../../../monitor/application/monitor_providers.dart';

class DevIntelMonitoringStatus extends ConsumerWidget {
  const DevIntelMonitoringStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(visibleMonitorDigestProvider);
    final digest = state.value;
    final repos = digest?.monitoredRepos.take(4).toList() ?? const <RepoEntity>[];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.tr('home.monitoring.title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.lg),
          if (state.isLoading && digest == null) const LinearProgressIndicator(),
          if (state.hasError && digest == null) Text(l10n.tr('monitor.check.failed.unknown')),
          if (!state.isLoading && !state.hasError && repos.isEmpty) Text(l10n.tr('monitor.empty')),
          for (var i = 0; i < repos.length; i++) ...[_StatusTile(repo: repos[i], check: digest?.checks[repos[i].fullName]), if (i != repos.length - 1) const SizedBox(height: AppSpacing.md)],
          const SizedBox(height: AppSpacing.lg),
          const _ConfigureButton(),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.repo, this.check});

  final RepoEntity repo;

  // 仓库真实检查状态，不从增长指标推断。
  final RepoCheckStatus? check;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repo.fullName,
          style: AppTypography.titleSmall.copyWith(color: colors.onSurface),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        RepoCheckStatusView(check: check),
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
          side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md2),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm))),
        ),
        child: Text(l10n.tr('home.monitoring.configure'), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ),
    );
  }
}
