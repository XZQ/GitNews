import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/discover_providers.dart';
import '../domain/discover_entities.dart';
import 'discover_navigation.dart';
import 'widgets/discover_load_more_indicator.dart';
import 'widgets/discover_profile_row.dart';
import 'widgets/discover_repo_row.dart';
import 'widgets/discover_segmented.dart';

/// 发现页:流行仓库 Top20 + Agent Skills 榜,行尾一键加/移监控。
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
    final extent = useCards ? discoverItemExtentCards : discoverItemExtentCompact;
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
          DiscoverSegmented(
            value: segment,
            compact: isCompact,
            onChanged: (v) => ref.read(discoverSegmentProvider.notifier).state = v,
          ),
          Expanded(
            child: switch (segment) {
              'skills' => _buildSkills(
                  ref.watch(filteredAgentSkillsProvider),
                  l10n,
                ),
              'official' => _buildProfiles(
                  filteredOfficialProfilesProvider,
                  l10n,
                  Icons.verified_outlined,
                  l10n.tr('discover.empty.official'),
                  DiscoverProfileKind.official,
                ),
              'people' => _buildProfiles(
                  filteredPeopleProfilesProvider,
                  l10n,
                  Icons.person_search_outlined,
                  l10n.tr('discover.empty.people'),
                  DiscoverProfileKind.people,
                ),
              _ => _buildRepos(ref.watch(filteredTrendingReposProvider), l10n),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRepos(
    AsyncValue<List<RepoEntity>> async,
    AppLocalizations l10n,
  ) {
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return EmptyView(
            icon: Icons.explore_off_outlined,
            message: query.trim().isEmpty ? l10n.tr('discover.empty.repos') : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        final hasMore = query.trim().isEmpty && ref.read(trendingReposNotifierProvider.notifier).hasMore;
        return ListView.separated(
          controller: _scrollController,
          padding: useCards
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                )
              : const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: repos.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => useCards ? const SizedBox(height: AppSpacing.md) : const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i >= repos.length) {
              return const DiscoverLoadMoreIndicator();
            }
            return DiscoverMonitorRow(
              repo: repos[i],
              cardStyle: useCards,
              onTap: () => context.go(
                discoverRepoDetailLocation(repos[i].fullName),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkills(
    AsyncValue<List<SkillEntity>> async,
    AppLocalizations l10n,
  ) {
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (skills) {
        if (skills.isEmpty) {
          return EmptyView(
            icon: Icons.extension_off_outlined,
            message: query.trim().isEmpty ? l10n.tr('discover.empty.skills') : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        final hasMore = query.trim().isEmpty && ref.read(agentSkillsNotifierProvider.notifier).hasMore;
        return ListView.separated(
          controller: _scrollController,
          padding: useCards
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                )
              : const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: skills.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => useCards ? const SizedBox(height: AppSpacing.md) : const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i >= skills.length) {
              return const DiscoverLoadMoreIndicator();
            }
            return DiscoverMonitorRow(
              repo: skills[i].repo,
              badge: '#${skills[i].rank} · ${skills[i].category}',
              cardStyle: useCards,
              onTap: () => context.go(
                discoverRepoDetailLocation(skills[i].repo.fullName),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfiles(
    ProviderListenable<AsyncValue<List<DiscoverProfileEntity>>> provider,
    AppLocalizations l10n,
    IconData emptyIcon,
    String emptyMessage,
    DiscoverProfileKind kind,
  ) {
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return EmptyView(
            icon: emptyIcon,
            message: query.trim().isEmpty ? emptyMessage : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        final notifierProvider = kind == DiscoverProfileKind.official ? officialProfilesNotifierProvider : peopleProfilesNotifierProvider;
        final hasMore = query.trim().isEmpty && ref.read(notifierProvider.notifier).hasMore;
        return ListView.separated(
          controller: _scrollController,
          padding: useCards
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                )
              : const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: profiles.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => useCards ? const SizedBox(height: AppSpacing.md) : const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i >= profiles.length) {
              return const DiscoverLoadMoreIndicator();
            }
            return DiscoverProfileRow(
              profile: profiles[i],
              cardStyle: useCards,
              onTap: () => context.go(
                discoverProfileDetailLocation(profiles[i]),
              ),
            );
          },
        );
      },
    );
  }
}
