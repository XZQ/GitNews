import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';

/*
 *发现页仓库卡片:仓库信息 + 行尾监控开关。
 *
 *监控开关直接读写 [localContentControllerProvider](core/shared),
 *与 monitor feature 共用 `monitoredRepos`,形成 discover→监控 闭环。
 *[badge] 用于 Agent Skills 榜展示「#排名 · 分类」。
 */
class DiscoverMonitorRow extends ConsumerWidget {
  const DiscoverMonitorRow({
    required this.repo,
    this.badge,
    this.onTap,
    this.embedded = false,
    super.key,
  });

  final RepoEntity repo;
  final String? badge;
  final VoidCallback? onTap;

  // 紧凑端分组卡片中的行不再重复绘制外框。
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final compact = Breakpoints.isCompact(context);
    final accent = Color(repo.accentArgb);
    final monitored = ref.watch(localContentControllerProvider.select((s) => s.isMonitored(repo.fullName)));
    final controller = ref.read(localContentControllerProvider.notifier);
    final radius = BorderRadius.circular(AppRadius.lg);
    final avatarSize = compact ? 40.0 : AppSpacing.xxl;
    final avatarAccent = _avatarAccent(repo.language, accent);
    final metricAccent = _metricAccent(repo.language, accent, colors.onSurfaceVariant);
    final avatarForeground = compact ? avatarAccent : accent;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(color: avatarAccent.withValues(alpha: compact ? 0.14 : 0.16), borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.sm)),
          alignment: Alignment.center,
          child: Text(
            repo.language.isNotEmpty ? repo.language.characters.first.toUpperCase() : '?',
            style: (compact ? AppTypography.headlineMedium : AppTypography.titleSmall).copyWith(color: avatarForeground, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopLine(fullName: repo.fullName, badge: badge, compact: compact),
              const SizedBox(height: AppSpacing.xs),
              Text(
                repo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant, height: compact ? 1.45 : 1.55),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (compact)
                _MobileMetrics(repo: repo, accent: metricAccent)
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(text: repo.language, color: accent),
                    _IconMetric(icon: Icons.star_rounded, value: _shortNumber(repo.starCount), color: AppColors.starGold),
                    _IconMetric(icon: Icons.call_split_rounded, value: _shortNumber(repo.forkCount), color: colors.secondary),
                  ],
                ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.sm),
          _MonitorButton(repo: repo, monitored: monitored, controller: controller, compact: false),
        ],
      ],
    );

    final interactive = Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: embedded ? Clip.none : Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: compact ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md2) : const EdgeInsets.all(AppSpacing.lg),
          child: compact
              ? Stack(
                  children: [
                    content,
                    Positioned(
                      right: -AppSpacing.lg,
                      bottom: -AppSpacing.md,
                      child: _MonitorButton(repo: repo, monitored: monitored, controller: controller, compact: true),
                    ),
                  ],
                )
              : content,
        ),
      ),
    );
    if (embedded) {
      return interactive;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.42 : 1)),
        boxShadow: [if (compact && isLight) BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: interactive,
    );
  }
}

/*
 *移动端指标区:主指标占一行,趋势口径与监控入口落在卡片底部。
 */
class _MobileMetrics extends StatelessWidget {
  const _MobileMetrics({required this.repo, required this.accent});

  final RepoEntity repo;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xxxl),
      child: Wrap(
        spacing: AppSpacing.sm2,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LanguageMetric(language: repo.language, color: accent),
          _IconMetric(icon: Icons.star_rounded, value: _shortNumber(repo.starCount), color: AppColors.starGold),
          _IconMetric(icon: Icons.call_split_rounded, value: _shortNumber(repo.forkCount), color: colors.primary),
          MetricBasisBadge(basis: repo.trendBasis),
        ],
      ),
    );
  }
}

/* 紧凑榜单的语言指标使用色点与纯文本，避免标签胶囊压缩仓库信息。 */
class _LanguageMetric extends StatelessWidget {
  const _LanguageMetric({required this.language, required this.color});

  final String language;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 7),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(language, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

/*
 *仓库监控按钮:移动端定位在卡片右下角,桌面端保留行尾操作位。
 */
class _MonitorButton extends StatelessWidget {
  const _MonitorButton({required this.repo, required this.monitored, required this.controller, required this.compact});

  final RepoEntity repo;
  final bool monitored;
  final LocalContentController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: monitored ? l10n.tr('discover.monitor_remove') : l10n.tr('discover.monitor_add'),
      icon: Icon(monitored ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: compact ? 20 : 22, color: monitored ? colors.primary : colors.onSurfaceVariant),
      onPressed: () async {
        if (monitored) {
          await controller.removeMonitor(repo.fullName);
        } else {
          await controller.addMonitor(repo);
        }
        if (!context.mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.tr(
                monitored ? 'discover.monitor_removed' : 'discover.monitor_added',
              ),
            ),
            action: SnackBarAction(
              label: l10n.tr('common.undo'),
              onPressed: () {
                if (monitored) {
                  controller.addMonitor(repo);
                } else {
                  controller.removeMonitor(repo.fullName);
                }
              },
            ),
          ),
        );
      },
      constraints: BoxConstraints(minWidth: compact ? 40 : 44, minHeight: compact ? 40 : 44),
    );
  }
}

class _TopLine extends StatelessWidget {
  const _TopLine({required this.fullName, required this.badge, required this.compact});

  final String fullName;
  final String? badge;
  final bool compact;

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
          style: (compact ? AppTypography.monoTitle : AppTypography.titleMedium).copyWith(color: colors.onSurface, fontWeight: FontWeight.w700, height: compact ? 1.3 : 1.35),
        )),
        if (badge != null) ...[const SizedBox(width: AppSpacing.sm), _Pill(text: badge!, color: colors.tertiary)]
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({required this.icon, required this.value, required this.color});

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
        Text(value, style: AppTypography.labelSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600))
      ],
    );
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

Color _avatarAccent(String language, Color fallback) => switch (language.toLowerCase()) {
      'markdown' => AppColors.brandDark,
      'typescript' => AppColors.langTypeScript,
      'python' => AppColors.success,
      '' || 'unknown' => AppColors.accentPurple,
      _ => fallback,
    };

Color _metricAccent(String language, Color fallback, Color unknown) => switch (language.toLowerCase()) {
      'markdown' || 'typescript' => AppColors.langTypeScript,
      'python' => AppColors.langPython,
      '' || 'unknown' => unknown,
      _ => fallback,
    };
