import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/header_search_field.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/discover_providers.dart';
import '../domain/discover_entities.dart';
import 'discover_sections.dart';
import 'widgets/discover_segmented.dart';

/*
 *发现页:流行仓库 Top20 + Agent Skills 榜,行尾一键加/移监控。
 */
class DiscoverHubPage extends ConsumerStatefulWidget {
  const DiscoverHubPage({super.key});

  @override
  ConsumerState<DiscoverHubPage> createState() => _DiscoverHubPageState();
}

class _DiscoverHubPageState extends ConsumerState<DiscoverHubPage> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      ref.read(discoverRefreshTickProvider.notifier).state++;
      ref.invalidate(trendingReposNotifierProvider);
      ref.invalidate(agentSkillsNotifierProvider);
      ref.invalidate(officialProfilesNotifierProvider);
      ref.invalidate(peopleProfilesNotifierProvider);
      switch (ref.read(discoverSegmentProvider)) {
        case 'skills':
          await ref.read(agentSkillsNotifierProvider.future);
        case 'official':
          if (Breakpoints.isCompact(context)) {
            await ref.read(filteredFeaturedProfilesProvider.future);
          } else {
            await ref.read(filteredOfficialProfilesProvider.future);
          }
        case 'people':
          await ref.read(filteredPeopleProfilesProvider.future);
        default:
          await ref.read(trendingReposNotifierProvider.future);
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  /* 监听内层列表剩余距离,不占用 [NestedScrollView] 的滚动控制器。 */
  bool _onScrollNotification(ScrollNotification notification) {
    if (ref.read(discoverSearchQueryProvider).trim().isNotEmpty) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final twoColumn = Breakpoints.isExpanded(context);
    final extent = twoColumn ? discoverItemExtentCards / 2 : discoverItemExtentCards;
    final remaining = notification.metrics.extentAfter / extent;
    if (remaining > discoverLoadMoreRemainingItems) {
      return false;
    }
    switch (ref.read(discoverSegmentProvider)) {
      case 'skills':
        ref.read(agentSkillsNotifierProvider.notifier).loadMore();
      case 'repos':
        ref.read(trendingReposNotifierProvider.notifier).loadMore();
      case 'official':
        ref.read(officialProfilesNotifierProvider.notifier).loadMore();
        if (Breakpoints.isCompact(context)) {
          ref.read(peopleProfilesNotifierProvider.notifier).loadMore();
        }
      case 'people':
        ref.read(peopleProfilesNotifierProvider.notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isCompact = Breakpoints.isCompact(context);
    final segment = ref.watch(discoverSegmentProvider);
    final visibleSegment = isCompact && segment == 'people' ? 'official' : segment;
    final query = ref.watch(discoverSearchQueryProvider);
    final content = NestedScrollView(
      physics: isCompact ? const AlwaysScrollableScrollPhysics() : null,
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        if (!isCompact)
          SliverToBoxAdapter(
            child: PageHeader(
              title: l10n.tr('discover.title'),
              subtitle: l10n.tr('discover.subtitle'),
              icon: Icons.explore_rounded,
              searchHint: l10n.tr('discover.search_hint'),
              searchValue: query,
              onSearchChanged: (value) => ref.read(discoverSearchQueryProvider.notifier).state = value,
              onRefresh: _refresh,
              isRefreshing: _refreshing,
            ),
          ),
        SliverToBoxAdapter(
          child: DiscoverSegmented(value: visibleSegment, compact: isCompact, onChanged: (value) => ref.read(discoverSegmentProvider.notifier).state = value),
        ),
      ],
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: switch (visibleSegment) {
          'skills' => DiscoverSkillsSection(async: ref.watch(filteredAgentSkillsProvider), onRetry: _refresh),
          'official' => DiscoverProfilesSection(
              provider: isCompact ? filteredFeaturedProfilesProvider : filteredOfficialProfilesProvider,
              emptyIcon: Icons.verified_outlined,
              emptyMessage: l10n.tr('discover.empty.official'),
              kind: isCompact ? null : DiscoverProfileKind.official,
              onRetry: _refresh,
            ),
          'people' => DiscoverProfilesSection(
              provider: filteredPeopleProfilesProvider,
              emptyIcon: Icons.person_search_outlined,
              emptyMessage: l10n.tr('discover.empty.people'),
              kind: DiscoverProfileKind.people,
              onRetry: _refresh,
            ),
          _ => DiscoverReposSection(async: ref.watch(filteredTrendingReposProvider), onRetry: _refresh),
        },
      ),
    );

    return Scaffold(
      // 移动端标题栏只保留标题与搜索框,刷新统一使用下拉手势。
      appBar: isCompact
          ? AppBar(
              toolbarHeight: 64,
              titleSpacing: AppSpacing.lg,
              title: Row(
                children: [
                  Text(
                    l10n.tr('discover.title'),
                    style: AppTypography.displayMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800, height: 1),
                  ),
                  const SizedBox(width: AppSpacing.lg2),
                  Expanded(
                    child: HeaderSearchField(
                      hintText: l10n.tr('discover.search_hint'),
                      value: query,
                      onChanged: (value) => ref.read(discoverSearchQueryProvider.notifier).state = value,
                      height: 40,
                      outlined: true,
                      fillColor: colors.surface,
                      borderRadius: AppRadius.xl,
                    ),
                  ),
                ],
              ),
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isCompact
          ? RefreshIndicator.adaptive(
              onRefresh: _refresh,
              notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical,
              child: content,
            )
          : content,
    );
  }
}
