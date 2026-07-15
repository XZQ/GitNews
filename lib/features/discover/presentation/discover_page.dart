import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
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
  late final ScrollController _scrollController;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          await ref.read(filteredOfficialProfilesProvider.future);
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

  void _onScroll() {
    if (ref.read(discoverSearchQueryProvider).trim().isNotEmpty) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    final useCards = !Breakpoints.isCompact(context);
    final twoColumn = Breakpoints.isExpanded(context);
    final extent = twoColumn ? discoverItemExtentCards / 2 : (useCards ? discoverItemExtentCards : discoverItemExtentCompact);
    final remaining = (_scrollController.position.maxScrollExtent - _scrollController.position.pixels) / extent;
    if (remaining > discoverLoadMoreRemainingItems) {
      return;
    }
    switch (ref.read(discoverSegmentProvider)) {
      case 'skills':
        ref.read(agentSkillsNotifierProvider.notifier).loadMore();
      case 'repos':
        ref.read(trendingReposNotifierProvider.notifier).loadMore();
      case 'official':
        ref.read(officialProfilesNotifierProvider.notifier).loadMore();
      case 'people':
        ref.read(peopleProfilesNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isCompact = Breakpoints.isCompact(context);
    final segment = ref.watch(discoverSegmentProvider);
    final freshness = ref.watch(discoverFreshnessProvider);
    final query = ref.watch(discoverSearchQueryProvider);

    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('discover.title'))) : null,
      backgroundColor: colors.surface,
      body: Column(
        children: [
          PageHeader(
            title: l10n.tr('discover.title'),
            subtitle: l10n.tr('discover.subtitle'),
            icon: Icons.explore_rounded,
            searchHint: l10n.tr('discover.search_hint'),
            searchValue: query,
            onSearchChanged: (v) => ref.read(discoverSearchQueryProvider.notifier).state = v,
            pills: [DataFreshnessBadge(freshness: freshness)],
            onRefresh: _refresh,
            isRefreshing: _refreshing,
          ),
          DiscoverSegmented(value: segment, compact: isCompact, onChanged: (v) => ref.read(discoverSegmentProvider.notifier).state = v),
          Expanded(
              child: switch (segment) {
            'skills' => DiscoverSkillsSection(async: ref.watch(filteredAgentSkillsProvider), scrollController: _scrollController, onRetry: _refresh),
            'official' => DiscoverProfilesSection(
                provider: filteredOfficialProfilesProvider,
                emptyIcon: Icons.verified_outlined,
                emptyMessage: l10n.tr('discover.empty.official'),
                kind: DiscoverProfileKind.official,
                scrollController: _scrollController,
                onRetry: _refresh,
              ),
            'people' => DiscoverProfilesSection(
                provider: filteredPeopleProfilesProvider,
                emptyIcon: Icons.person_search_outlined,
                emptyMessage: l10n.tr('discover.empty.people'),
                kind: DiscoverProfileKind.people,
                scrollController: _scrollController,
                onRetry: _refresh,
              ),
            _ => DiscoverReposSection(async: ref.watch(filteredTrendingReposProvider), scrollController: _scrollController, onRetry: _refresh)
          })
        ],
      ),
    );
  }
}
