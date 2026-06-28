import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/monitor_providers.dart';

/// 告警列表(全量)。
class MonitorAlertsPage extends ConsumerWidget {
  const MonitorAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警列表'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: state.when(
        data: (digest) {
          if (digest.alerts.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none_rounded,
              message: '近 24 小时暂无告警',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Body(alerts: digest.alerts),
            medium: (_) => CenteredContent(child: _Body(alerts: digest.alerts)),
            expanded: (_) =>
                CenteredContent(child: _Body(alerts: digest.alerts)),
          );
        },
        loading: () => const _AlertsSkeleton(),
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

class _Body extends StatelessWidget {
  const _Body({required this.alerts});

  final List<DemoAlert> alerts;

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
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '所有告警',
                  subtitle: '近 24 小时 · 共 ${alerts.length} 条',
                ),
              ),
              for (var i = 0; i < alerts.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                _AlertFullTile(alert: alerts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
      ],
    );
  }
}

class _AlertFullTile extends StatelessWidget {
  const _AlertFullTile({required this.alert});
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
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
          const SizedBox(width: AppSpacing.sm),
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
