import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import '../widgets/trending_language_panel.dart';
import '../widgets/trending_metrics.dart';
import '../widgets/trending_page_header.dart';
import '../widgets/trending_topics_panel.dart';

class TrendingPage extends ConsumerWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(trendingDigestProvider);
    return Scaffold(
      appBar: isCompact ? AppBar(title: const Text('趋势')) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty) {
            return const EmptyView(
              icon: Icons.local_fire_department_outlined,
              message: '暂无趋势数据',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _TrendingMobile(digest: digest),
            medium: (_) => _TrendingDesktop(digest: digest),
            expanded: (_) => _TrendingDesktop(digest: digest),
          );
        },
        loading: () => const _TrendingSkeleton(),
        error: (error, stackTrace) => ErrorView(
          error: AppException(kind: AppExceptionKind.unknown, cause: error),
          onRetry: () => ref.invalidate(trendingDigestProvider),
        ),
      ),
    );
  }
}

/// 手机:时间窗 / 筛选 + Hero 趋势图 + 列表 + 趋势主题。
class _TrendingMobile extends StatefulWidget {
  const _TrendingMobile({required this.digest});

  final TrendingDigest digest;

  @override
  State<_TrendingMobile> createState() => _TrendingMobileState();
}

class _TrendingMobileState extends State<_TrendingMobile> {
  String _window = 'today';
  String _lang = 'all';

  @override
  Widget build(BuildContext context) {
    final windowLabel = const {
      'today': '今日',
      'week': '本周',
      'month': '本月',
    }[_window]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Star 增长榜', style: AppTypography.titleLarge),
                  ),
                  TrendingPopupMenu(
                    value: _lang,
                    options: const ['all', 'typescript', 'python', 'rust'],
                    optionLabel: (v) => const {
                      'all': '全部语言',
                      'typescript': 'TypeScript',
                      'python': 'Python',
                      'rust': 'Rust',
                    }[v]!,
                    onSelected: (v) => setState(() => _lang = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '追踪 $windowLabel · Star 增速排名',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TrendingWindowSegmented(
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const TrendingHeroMetrics(),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: widget.digest.primaryTrend,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ChartSeries(
                    values: widget.digest.secondaryTrend,
                    color: AppColors.success,
                  ),
                ],
                height: 200,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
                  title: '热门仓库',
                  subtitle:
                      '$windowLabel · ${widget.digest.trendingRepos.length} 个项目',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('筛选'),
                  ),
                ),
              ),
              for (var i = 0; i < widget.digest.trendingRepos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: widget.digest.trendingRepos[i],
                  onTap: () => context.go(
                    '/repo_detail/${Uri.encodeComponent(widget.digest.trendingRepos[i].fullName)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const TrendingTopicsPanel(),
      ],
    );
  }
}

/// 桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
class _TrendingDesktop extends StatefulWidget {
  const _TrendingDesktop({required this.digest});

  final TrendingDigest digest;

  @override
  State<_TrendingDesktop> createState() => _TrendingDesktopState();
}

class _TrendingDesktopState extends State<_TrendingDesktop> {
  String _lang = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrendingPageHeader(),
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
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Star 增长趋势',
                        subtitle: '追踪时间窗内的新增 Star 总量 · 包含所有语言',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StarTrendChart(
                        series: [
                          ChartSeries(
                            values: widget.digest.primaryTrend,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          ChartSeries(
                            values: widget.digest.secondaryTrend,
                            color: AppColors.info,
                          ),
                          ChartSeries(
                            values: widget.digest.tertiaryTrend,
                            color: AppColors.success,
                          ),
                        ],
                        height: 280,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 8,
                      child: _TrendingList(repos: widget.digest.trendingRepos),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          TrendingLanguagePanel(
                            value: _lang,
                            onChanged: (v) => setState(() => _lang = v),
                            languages: widget.digest.languages,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const TrendingTopicsPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList({required this.repos});

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
              title: '热门仓库',
              subtitle: '按 Star 增速排序',
            ),
          ),
          for (var i = 0; i < repos.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: repos[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(repos[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(height: 64),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 280),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 320),
        ],
      ),
    );
  }
}
