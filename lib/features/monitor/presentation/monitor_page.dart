import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/monitor_providers.dart';
import '../domain/monitor_repository.dart';
import '../widgets/monitor_page_header.dart';
import '../widgets/monitor_settings_cards.dart';

class MonitorPage extends ConsumerWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(monitorDigestProvider);
    return Scaffold(
      appBar: isCompact ? AppBar(title: const Text('监控')) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty) {
            return const EmptyView(
              icon: Icons.visibility_off_outlined,
              message: '还没有监控仓库',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Mobile(digest: digest),
            medium: (_) => _Desktop(digest: digest),
            expanded: (_) => _Desktop(digest: digest),
          );
        },
        loading: () => const _MonitorSkeleton(),
        error: (error, stack) => ErrorView(
          error: _toAppException(error, stack),
          onRetry: () => ref.invalidate(monitorDigestProvider),
        ),
      ),
    );
  }

  AppException _toAppException(Object error, StackTrace stack) {
    if (error is AppException) return error;
    return AppException(
      kind: AppExceptionKind.unknown,
      cause: error,
      stack: stack,
    );
  }
}

/// 手机:状态 4 卡 + 我的监控仓库 + 最近告警。
class _Mobile extends StatelessWidget {
  const _Mobile({required this.digest});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        _StatusRow(stats: digest.stats),
        const SizedBox(height: AppSpacing.lg),
        _MonitoredRepos(repos: digest.monitoredRepos),
        const SizedBox(height: AppSpacing.lg),
        _RecentAlerts(alerts: digest.alerts),
      ],
    );
  }
}

/// 桌面:左 8 列监控仓库表 + 告警 / 右 4 列(规则 + 通知设置)。
class _Desktop extends StatelessWidget {
  const _Desktop({required this.digest});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MonitorPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusRow(stats: digest.stats),
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 8,
                        child: _MonitoredRepos(repos: digest.monitoredRepos),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: _RightColumn(alerts: digest.alerts),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.stats});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            label: '监控仓库',
            value: '${stats.monitoredCount}',
            delta: _formatDelta(stats.monitoredDelta),
            icon: Icons.visibility_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatusCard(
            label: '未读告警',
            value: '${stats.unreadAlertCount}',
            delta: _formatDelta(stats.unreadAlertDelta),
            icon: Icons.error_outline,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatusCard(
            label: '今日触发',
            value: '${stats.triggeredTodayCount}',
            delta: _formatDelta(stats.triggeredTodayDelta),
            icon: Icons.bolt_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatusCard(
            label: '告警总数',
            value: '${stats.totalAlertCount}',
            delta: _formatDelta(stats.totalAlertDelta),
            icon: Icons.history_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  String _formatDelta(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoredRepos extends StatelessWidget {
  const _MonitoredRepos({required this.repos});

  final List<DemoRepo> repos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '我的监控仓库',
              subtitle: '近 30 天 Star 增速与告警',
            ),
          ),
          for (var i = 0; i < repos.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _MonitoredRow(repo: repos[i]),
          ],
        ],
      ),
    );
  }
}

class _MonitoredRow extends StatelessWidget {
  const _MonitoredRow({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(
        '/repo_detail/${Uri.encodeComponent(repo.fullName)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(repo.color).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language[0],
                style: AppTypography.labelMedium.copyWith(
                  color: Color(repo.color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, style: AppTypography.titleSmall),
                  Text(
                    repo.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Sparkline(
              values: DemoData.generateStarTrend(
                repo.starCount - 5000,
                5000,
              ),
              color: AppColors.success,
              width: 90,
              height: 32,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '正常',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  const _RecentAlerts({required this.alerts});

  final List<DemoAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '最近告警',
              subtitle: '今日与昨日告警流',
            ),
          ),
          for (var i = 0; i < alerts.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _AlertRow(alert: alerts[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final DemoAlert alert;

  Color _accent() {
    return switch (alert.severity) {
      AlertSeverity.success => AppColors.success,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.danger => AppColors.danger,
      AlertSeverity.info => AppColors.info,
    };
  }

  IconData _icon() {
    return switch (alert.severity) {
      AlertSeverity.success => Icons.trending_up_rounded,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.danger => Icons.error_outline,
      AlertSeverity.info => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(), color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.repo, style: AppTypography.titleSmall),
                Text(
                  alert.metric,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert.value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert.time,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.alerts});

  final List<DemoAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MonitorRulesCard(),
        const SizedBox(height: AppSpacing.lg),
        const MonitorNotificationCard(),
        const SizedBox(height: AppSpacing.lg),
        _RecentAlerts(alerts: alerts),
      ],
    );
  }
}

class _MonitorSkeleton extends StatelessWidget {
  const _MonitorSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: const [
        Row(
          children: [
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 360),
      ],
    );
  }
}
