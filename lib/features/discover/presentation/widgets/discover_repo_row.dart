import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/repo_tile.dart';

/// 发现页仓库卡片:仓库信息 + 行尾监控开关。
///
/// 监控开关直接读写 [localContentControllerProvider](core/shared),
/// 与 monitor feature 共用 `monitoredRepos`,形成 discover→监控 闭环。
/// [badge] 用于 Agent Skills 榜展示「#排名 · 分类」。
class DiscoverMonitorRow extends ConsumerWidget {
  const DiscoverMonitorRow({
    required this.repo,
    this.badge,
    this.onTap,
    this.cardStyle = true,
    super.key,
  });

  final RepoEntity repo;
  final String? badge;
  final VoidCallback? onTap;
  final bool cardStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = Color(repo.accentArgb);
    final monitored = ref.watch(
      localContentControllerProvider.select(
        (s) => s.isMonitored(repo.fullName),
      ),
    );
    final controller = ref.read(localContentControllerProvider.notifier);
    if (!cardStyle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (badge != null) ...[
            _Pill(text: badge!, color: colors.tertiary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: RepoTile(repo: repo, onTap: onTap),
          ),
          IconButton(
            tooltip: monitored ? l10n.tr('discover.monitor_remove') : l10n.tr('discover.monitor_add'),
            icon: Icon(
              monitored ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
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
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  repo.language.isNotEmpty ? repo.language.characters.first.toUpperCase() : '?',
                  style: AppTypography.titleSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopLine(
                      fullName: repo.fullName,
                      badge: badge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      repo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(text: repo.language, color: accent),
                        _IconMetric(
                          icon: Icons.star_rounded,
                          value: _shortNumber(repo.starCount),
                          color: AppColors.starGold,
                        ),
                        _IconMetric(
                          icon: Icons.call_split_rounded,
                          value: _shortNumber(repo.forkCount),
                          color: colors.secondary,
                        ),
                        _DeltaPill(value: repo.starDelta),
                        DataProvenanceBadge(provenance: repo.trendProvenance),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: monitored ? l10n.tr('discover.monitor_remove') : l10n.tr('discover.monitor_add'),
                icon: Icon(
                  monitored ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLine extends StatelessWidget {
  const _TopLine({
    required this.fullName,
    required this.badge,
  });

  final String fullName;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _Pill(text: badge!, color: colors.tertiary),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? AppColors.success : AppColors.danger;
    return _Pill(text: value >= 0 ? '+${_shortNumber(value)}' : _shortNumber(value), color: color);
  }
}

String _shortNumber(int v) {
  final abs = v.abs();
  final prefix = v < 0 ? '-' : '';
  if (abs >= 1000000) {
    return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    return '$prefix${(abs / 1000).toStringAsFixed(1)}k';
  }
  return v.toString();
}
