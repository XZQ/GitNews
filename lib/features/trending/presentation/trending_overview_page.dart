import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/observed_repo_growth.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/repo_growth_chart.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../project/application/project_providers.dart';

/* 
*二级页 1:Star 增长趋势(全量)。
*/
class TrendingOverviewPage extends ConsumerWidget {
  const TrendingOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDigestProvider);
    return SecondaryPageScaffold(
      title: 'Star 增长趋势',
      subtitle: '跨仓库趋势总览',
      icon: Icons.show_chart_rounded,
      fallbackPath: '/home',
      body: ResponsiveLayout(
        compact: (_) => _Body(state: state),
        medium: (_) => CenteredContent(child: _Body(state: state)),
        expanded: (_) => CenteredContent(child: _Body(state: state)),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final AsyncValue<ProjectDigest> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      data: (digest) => digest.isEmpty ? const EmptyView(icon: Icons.show_chart_rounded, message: '暂无趋势数据') : _DigestView(digest: digest),
      loading: () => const _OverviewSkeleton(),
      error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(projectDigestProvider)),
    );
  }
}

class _DigestView extends StatelessWidget {
  const _DigestView({required this.digest});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Star 观测净变化', subtitle: '最近 30 天 · 当前项目样本'),
              const SizedBox(height: AppSpacing.md),
              RepoGrowthChart(repos: digest.repos),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '按时间窗统计', subtitle: '所选时段内首末共同观测的净变化'),
              const SizedBox(height: AppSpacing.md),
              _WindowStatsTable(repos: digest.repos),
            ],
          ),
        ),
      ],
    );
  }
}

class _WindowStatsTable extends StatelessWidget {
  const _WindowStatsTable({required this.repos});
  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final days in [1, 7, 30]) _row(days),
    ];
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1)},
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          children: const [_Th('时间窗'), _Th('净变化'), _Th('实际日期 UTC'), _Th('样本覆盖')],
        ),
        for (final r in rows) TableRow(children: [_Td(r[0]), _Td(r[1]), _Td(r[2]), _Td(r[3])]),
      ],
    );
  }

  List<String> _row(int days) {
    final growth = ObservedRepoGrowth.fromRepos(repos, days: days);
    final delta = growth.netChange;
    return [
      '近 $days 天',
      delta == null ? '待积累' : '${delta >= 0 ? '+' : ''}$delta',
      growth.isEmpty ? '—' : '${growth.dates.first.toIso8601String().substring(0, 10)} — ${growth.dates.last.toIso8601String().substring(0, 10)}',
      '${growth.sampleCount}/${growth.totalCount}',
    ];
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _Td extends StatelessWidget {
  const _Td(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm2),
      child: Text(text, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: const [
        Skeleton(height: 320),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 200),
      ],
    );
  }
}
