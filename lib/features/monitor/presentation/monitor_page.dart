import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/monitor_providers.dart';
import '../domain/monitor_repository.dart';
import '../widgets/monitor_monitored_repos.dart';
import '../widgets/monitor_page_header.dart';
import '../widgets/monitor_recent_alerts.dart';
import '../widgets/monitor_settings_cards.dart';
import '../widgets/monitor_status_row.dart';

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
        MonitorStatusRow(stats: digest.stats),
        const SizedBox(height: AppSpacing.lg),
        MonitorMonitoredRepos(repos: digest.monitoredRepos),
        const SizedBox(height: AppSpacing.lg),
        MonitorRecentAlerts(alerts: digest.alerts),
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
                MonitorStatusRow(stats: digest.stats),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 280)
                      .clamp(220.0, 900.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 8,
                        child: MonitorMonitoredRepos(
                          repos: digest.monitoredRepos,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: _RightColumn(alerts: digest.alerts),
                        ),
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
        MonitorRecentAlerts(alerts: alerts),
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
