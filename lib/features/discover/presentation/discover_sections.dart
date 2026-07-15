import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/discover_providers.dart';
import '../domain/discover_entities.dart';
import 'discover_navigation.dart';
import 'widgets/discover_load_more_indicator.dart';
import 'widgets/discover_profile_row.dart';
import 'widgets/discover_repo_row.dart';

class DiscoverReposSection extends ConsumerWidget {
  const DiscoverReposSection({
    required this.async,
    required this.scrollController,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<RepoEntity>> async;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e), onRetry: onRetry),
        data: (repos) {
          if (repos.isEmpty) {
            return EmptyView(icon: Icons.explore_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.repos') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
          }
          final hasMore = query.trim().isEmpty && ref.read(trendingReposNotifierProvider.notifier).hasMore;
          return ListView.separated(
              controller: scrollController,
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
                return DiscoverMonitorRow(repo: repos[i], cardStyle: useCards, onTap: () => context.go(discoverRepoDetailLocation(repos[i].fullName)));
              });
        });
  }
}

class DiscoverSkillsSection extends ConsumerWidget {
  const DiscoverSkillsSection({
    required this.async,
    required this.scrollController,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<SkillEntity>> async;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e), onRetry: onRetry),
        data: (skills) {
          if (skills.isEmpty) {
            return EmptyView(icon: Icons.extension_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.skills') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
          }
          final hasMore = query.trim().isEmpty && ref.read(agentSkillsNotifierProvider.notifier).hasMore;
          return ListView.separated(
              controller: scrollController,
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
                  onTap: () => context.go(discoverRepoDetailLocation(skills[i].repo.fullName)),
                );
              });
        });
  }
}

class DiscoverProfilesSection extends ConsumerWidget {
  const DiscoverProfilesSection({
    required this.provider,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.kind,
    required this.scrollController,
    required this.onRetry,
    super.key,
  });

  final ProviderListenable<AsyncValue<List<DiscoverProfileEntity>>> provider;
  final IconData emptyIcon;
  final String emptyMessage;
  final DiscoverProfileKind kind;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    final async = ref.watch(provider);
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e), onRetry: onRetry),
        data: (profiles) {
          if (profiles.isEmpty) {
            return EmptyView(icon: emptyIcon, message: query.trim().isEmpty ? emptyMessage : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
          }
          final notifierProvider = kind == DiscoverProfileKind.official ? officialProfilesNotifierProvider : peopleProfilesNotifierProvider;
          final hasMore = query.trim().isEmpty && ref.read(notifierProvider.notifier).hasMore;
          return ListView.separated(
              controller: scrollController,
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
                return DiscoverProfileRow(profile: profiles[i], cardStyle: useCards, onTap: () => context.go(discoverProfileDetailLocation(profiles[i])));
              });
        });
  }
}
