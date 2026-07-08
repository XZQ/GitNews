import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/repo_tile.dart';

/// 发现页仓库行:RepoTile + 行尾监控开关。
///
/// 监控开关直接读写 [localContentControllerProvider](core/shared),
/// 与 monitor feature 共用 `monitoredRepos`,形成 discover→监控 闭环。
/// [badge] 用于 Agent Skills 榜展示「#排名 · 分类」。
class DiscoverMonitorRow extends ConsumerWidget {
  const DiscoverMonitorRow({
    required this.repo,
    this.badge,
    this.onTap,
    super.key,
  });

  final RepoEntity repo;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final monitored = ref.watch(
      localContentControllerProvider.select(
        (s) => s.isMonitored(repo.fullName),
      ),
    );
    final controller = ref.read(localContentControllerProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: colors.tertiary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              badge!,
              style: AppTypography.labelSmall.copyWith(
                color: colors.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: RepoTile(repo: repo, onTap: onTap),
        ),
        IconButton(
          tooltip: monitored
              ? l10n.tr('discover.monitor_remove')
              : l10n.tr('discover.monitor_add'),
          icon: Icon(
            monitored
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: monitored ? colors.primary : colors.onSurfaceVariant,
          ),
          onPressed: () async {
            if (monitored) {
              await controller.removeMonitor(repo.fullName);
            } else {
              await controller.addMonitor(repo.fullName);
            }
          },
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
