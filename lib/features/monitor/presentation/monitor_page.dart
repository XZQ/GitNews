import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';
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
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(filteredMonitorDigestProvider);
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('monitor.title'))) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty) {
            return EmptyView(
              icon: Icons.visibility_off_outlined,
              message: l10n.tr('monitor.empty'),
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
          error: error.asAppException(stack),
          onRetry: () => forceRefreshMonitor(ref),
        ),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.digest});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: MonitorStatusRow(stats: digest.stats),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _MobileQuickActions()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: l10n.tr('monitor.monitored_repos.title'),
              subtitle: l10n.tr('monitor.monitored_repos.subtitle'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: digest.monitoredRepos.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => MonitorMonitoredRow(
              repo: digest.monitoredRepos[index],
              dense: true,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: MonitorRecentAlerts(alerts: digest.alerts),
          ),
        ),
      ],
    );
  }
}

class _MobileQuickActions extends StatelessWidget {
  const _MobileQuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.notifications_outlined,
            label: l10n.tr('monitor.quick.alerts'),
            onTap: () => context.go('/monitor/alerts'),
          ),
          _QuickAction(
            icon: Icons.rule_outlined,
            label: l10n.tr('monitor.quick.rules'),
            onTap: () => context.go('/profile/rules'),
          ),
          _QuickAction(
            icon: Icons.tune_rounded,
            label: l10n.tr('monitor.quick.settings'),
            onTap: () => context.go('/monitor/settings'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Desktop extends ConsumerWidget {
  const _Desktop({required this.digest});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(monitorSearchQueryProvider).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitorPageHeader(stats: digest.stats),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonitorStatusRow(stats: digest.stats),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
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
                          child: _RightColumn(
                            alerts: digest.alerts,
                            searchQuery: searchQuery,
                          ),
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
  const _RightColumn({required this.alerts, required this.searchQuery});

  final List<AlertEntity> alerts;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitorRulesCard(query: searchQuery),
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
