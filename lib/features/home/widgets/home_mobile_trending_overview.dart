import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import 'home_mobile_hot_repos_card.dart';
import 'home_mobile_star_growth_card.dart';

/*
* 移动总览中的 GitHub 热榜区块：热门仓库榜单卡片 + Star 增长榜图表。
*
* 话题趋势同属热榜数据，但设计稿把它排在 AI 雷达之后，因此由
*   `HomeMobileRadarOverview` 渲染，不在本区块内。
*/
class HomeMobileTrendingOverview extends ConsumerStatefulWidget {
  const HomeMobileTrendingOverview({super.key});

  @override
  ConsumerState<HomeMobileTrendingOverview> createState() => _HomeMobileTrendingOverviewState();
}

class _HomeMobileTrendingOverviewState extends ConsumerState<HomeMobileTrendingOverview> {
  final Map<String, TrendingDigest> _starDigestCache = {};
  TrendingDigest? _lastStarDigest;
  String? _lastStarWindow;

  /* 构建热榜两块内容及统一的加载和错误状态。 */
  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(trendingHomeDigestProvider);
    final starState = ref.watch(trendingDigestProvider);
    final selectedWindow = ref.watch(trendingWindowFilterProvider);
    final currentDigest = starState.value;
    if (currentDigest != null) {
      _starDigestCache[selectedWindow] = currentDigest;
      _lastStarDigest = currentDigest;
      _lastStarWindow = selectedWindow;
    }
    final selectedDigest = _starDigestCache[selectedWindow];
    final visibleDigest = selectedDigest ?? _lastStarDigest;
    final visibleWindow = selectedDigest == null ? (_lastStarWindow ?? selectedWindow) : selectedWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        homeState.when(
          data: (digest) => _HomeHotReposSection(digest: digest),
          loading: () => const Skeleton(height: 260),
          error: (error, stack) => ErrorView(
            error: error.asAppException(stack),
            onRetry: () {
              ref.invalidate(trendingHomeDigestResultProvider);
              ref.invalidate(trendingHomeDigestProvider);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visibleDigest != null)
          Stack(
            children: [
              HomeMobileStarGrowthCard(digest: visibleDigest, dataWindow: visibleWindow),
              if (starState.isLoading)
                Positioned(
                  top: 0,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                    child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                  ),
                ),
            ],
          )
        else
          starState.when(
            data: (digest) => HomeMobileStarGrowthCard(digest: digest, dataWindow: selectedWindow),
            loading: () => const Skeleton(height: 320),
            error: (error, stack) => ErrorView(
              error: error.asAppException(stack),
              onRetry: () {
                ref.invalidate(trendingDigestResultProvider);
                ref.invalidate(trendingDigestProvider);
              },
            ),
          ),
      ],
    );
  }
}

class _HomeHotReposSection extends StatelessWidget {
  const _HomeHotReposSection({required this.digest});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repos = digest.trendingRepos.take(3).toList(growable: false);
    return HomeMobileHotReposCard(
      repos: repos,
      meta: l10n.tr('trending.mobile.repos_count').replaceAll('{window}', l10n.tr('trending.window.today')).replaceAll('{count}', '${repos.length}'),
      title: l10n.tr('trending.page.repos'),
      emptyMessage: l10n.tr('trending.hot_repos.empty'),
    );
  }
}
