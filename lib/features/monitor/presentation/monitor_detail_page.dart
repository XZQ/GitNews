import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
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

/// 监控详情(对应监控页二级稿:实时趋势 + 告警历史)。
class MonitorDetailPage extends ConsumerWidget {
  const MonitorDetailPage({required this.repoFullName, super.key});

  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: state.when(
        data: (digest) {
          if (digest.monitoredRepos.isEmpty) {
            return const EmptyView(
              icon: Icons.visibility_off_outlined,
              message: '还没有监控仓库',
            );
          }
          final repo = digest.repoByFullName(repoFullName);
          return ResponsiveLayout(
            compact: (_) => _Body(repo: repo, alerts: digest.alerts),
            medium: (_) => CenteredContent(
              child: _Body(repo: repo, alerts: digest.alerts),
            ),
            expanded: (_) => CenteredContent(
              child: _Body(repo: repo, alerts: digest.alerts),
            ),
          );
        },
        loading: () => const _DetailSkeleton(),
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
  const _Body({required this.repo, required this.alerts});

  final DemoRepo repo;
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
        GradientHeroHeader(
          accent: Color(repo.color),
          title: repo.fullName,
          badges: [
            HeroBadge(
              label: repo.language,
              icon: Icons.bolt_rounded,
            ),
            HeroBadge(
              label: '★ ${_shortNumber(repo.starCount)}',
              icon: Icons.star_rounded,
            ),
            HeroBadge(
              label: '⑂ ${_shortNumber(repo.forkCount)}',
              icon: Icons.call_split_rounded,
            ),
          ],
          trailing: Text(
            repo.description,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '实时趋势',
                subtitle: '最近 24 小时 Star / Fork 变化',
              ),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: DemoData.generateStarTrend(
                      repo.starCount - 5000,
                      5000,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ChartSeries(
                    values: DemoData.generateStarTrend(repo.forkCount, 800),
                    color: AppColors.info,
                  ),
                ],
                height: 220,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '告警历史',
                subtitle: '本仓库触发的所有告警',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final alert in alerts.take(5)) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(alert.repo, style: AppTypography.titleSmall),
                  subtitle: Text('${alert.metric} · ${alert.time}'),
                  trailing: Text(
                    alert.value,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
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
      children: const [
        Skeleton(height: 180),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 300),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 260),
      ],
    );
  }
}

String _shortNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
