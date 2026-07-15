import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/gradient_hero_header.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';
import '../widgets/monitor_alert_list_tile.dart';

/* 
*监控详情(对应监控页二级稿:实时趋势 + 告警历史)。
*/
class MonitorDetailPage extends ConsumerWidget {
  const MonitorDetailPage({required this.repoFullName, super.key});

  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(visibleMonitorDigestProvider);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.tr('monitor.detail_title')), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/monitor'))),
        body: state.when(
            data: (digest) {
              if (digest.monitoredRepos.isEmpty) {
                return EmptyView(icon: Icons.visibility_off_outlined, message: l10n.tr('monitor.empty'));
              }
              final repo = digest.repoByFullName(repoFullName);
              if (repo == null) {
                return EmptyView(icon: Icons.visibility_off_outlined, message: l10n.tr('monitor.empty.not_in_list'));
              }
              return ResponsiveLayout(
                compact: (_) => _Body(repo: repo, alerts: digest.alerts),
                medium: (_) => CenteredContent(child: _Body(repo: repo, alerts: digest.alerts)),
                expanded: (_) => CenteredContent(child: _Body(repo: repo, alerts: digest.alerts)),
              );
            },
            loading: () => const _DetailSkeleton(),
            error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => forceRefreshMonitor(ref))));
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.repo, required this.alerts});

  final RepoEntity repo;
  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repoAlerts = alerts.where((alert) => alert.repoFullName == repo.fullName).take(5);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        GradientHeroHeader(
          accent: Color(repo.accentArgb),
          title: repo.fullName,
          badges: [
            HeroBadge(label: repo.language, icon: Icons.bolt_rounded),
            HeroBadge(label: '★ ${_shortNumber(repo.starCount)}', icon: Icons.star_rounded),
            HeroBadge(label: '⑂ ${_shortNumber(repo.forkCount)}', icon: Icons.call_split_rounded)
          ],
          trailing: Text(repo.description, style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.92))),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('monitor.section.realtime_trend'), subtitle: '${l10n.tr('monitor.section.realtime_trend.subtitle')} · ${l10n.tr(repo.trendBasis.labelKey)}'),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(values: repo.trend ?? _estimatedTrend(repo.starCount - 5000, 5000), color: Theme.of(context).colorScheme.primary),
                  ChartSeries(values: _estimatedTrend(repo.forkCount, 800), color: AppColors.info)
                ],
                height: 220,
              )
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('monitor.section.alert_history'), subtitle: l10n.tr('monitor.section.alert_history.subtitle')),
              const SizedBox(height: AppSpacing.md),
              for (final alert in repoAlerts) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text(alert.repoFullName, style: AppTypography.titleSmall),
                  subtitle: Text('${monitorAlertMetricLabel(context, alert)} · ${alert.time}'),
                  trailing: Text(alert.value, style: AppTypography.labelMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: AppSpacing.xs)
              ]
            ],
          ),
        )
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [Skeleton(height: 180), SizedBox(height: AppSpacing.lg), Skeleton(height: 300), SizedBox(height: AppSpacing.lg), Skeleton(height: 260)],
    );
  }
}

String _shortNumber(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}k';
  }
  return '$n';
}

List<double> _estimatedTrend(int base, int delta, {int count = 30}) {
  final last = count - 1;
  return List<double>.generate(count, (i) {
    final progress = last == 0 ? 0.0 : i / last;
    final noise = ((i * 13) % 7) - 3;
    return (base + delta * progress + noise).toDouble();
  });
}
