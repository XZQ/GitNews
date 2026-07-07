import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import '../widgets/language_donut_chart.dart';
import '../widgets/language_growth_bars.dart';

/* 二级页 2:语言趋势(饼图 + 列表)。 */
class LanguageTrendPage extends ConsumerWidget {
  const LanguageTrendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trendingDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言趋势'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trending'),
        ),
      ),
      body: state.when(
        data: (digest) {
          if (digest.languages.isEmpty) {
            return const EmptyView(
              icon: Icons.code_rounded,
              message: '暂无语言趋势',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Body(digest: digest),
            medium: (_) => CenteredContent(child: _Body(digest: digest)),
            expanded: (_) => CenteredContent(child: _Body(digest: digest)),
          );
        },
        loading: () => const _PageSkeleton(),
        error: (error, stackTrace) => ErrorView(
          error: AppException(
            kind: AppExceptionKind.unknown,
            cause: error,
            stack: stackTrace,
          ),
          onRetry: () => ref.invalidate(trendingDigestProvider),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.digest});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
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
              const SectionHeader(
                title: '语言趋势总览',
                subtitle: '热门仓库的编程语言占比 · 最近 30 天',
              ),
              const SizedBox(height: AppSpacing.lg),
              LanguageDonutChart(
                data: digest.languages,
                holeColor:
                    isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final l in digest.languages) ...[
                LanguageDistributionRow(
                  name: l.name,
                  percent: l.percent,
                  delta: l.delta,
                  color: Color(l.accentArgb),
                ),
                const SizedBox(height: AppSpacing.sm2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '语言增长率排行',
                subtitle: '本周 vs 上周',
              ),
              const SizedBox(height: AppSpacing.md),
              LanguageGrowthBars(languages: digest.languages),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Skeleton(height: 360),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 240),
        ],
      ),
    );
  }
}
