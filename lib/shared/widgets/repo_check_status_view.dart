import 'package:flutter/material.dart';

import '../../core/config/cache_ttl_config.dart';
import '../../core/domain/repo_check_status.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/relative_time_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/*
*统一显示仓库检查结果与实际时间，不根据 Star 增量推断健康。
*/
class RepoCheckStatusView extends StatelessWidget {
  const RepoCheckStatusView({this.check, this.now, super.key});

  // 缺少状态的旧缓存显示未检查。
  final RepoCheckStatus? check;

  // 可注入时钟以验证缓存过期边界。
  final DateTime? now;

  @override
  /* 长原因和时间允许换行，精确本地时间放在提示中。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final current = now ?? DateTime.now();
    final validated = check?.validatedAt;
    final attempted = check?.attemptedAt;
    final failure = check?.failure;
    final expired = validated != null && current.difference(validated) >= CacheTtlConfig.monitor;
    final status = failure != null
        ? 'monitor.check.failed.${failure.name}'
        : validated == null
        ? 'monitor.check.pending'
        : expired
        ? 'monitor.check.stale'
        : 'monitor.check.success';
    final color = failure != null || expired
        ? AppColors.warning
        : validated == null
        ? colors.onSurfaceVariant
        : AppColors.success;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.tr(status),
          style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        if (validated != null)
          Tooltip(
            message: validated.toLocal().toString(),
            child: Text(
              l10n.tr('monitor.check.last_success').replaceAll('{time}', formatRelativeTime(l10n, validated, now: current)),
              style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        if (failure != null && attempted != null)
          Tooltip(
            message: attempted.toLocal().toString(),
            child: Text(
              l10n.tr('monitor.check.last_attempt').replaceAll('{time}', formatRelativeTime(l10n, attempted, now: current)),
              style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
