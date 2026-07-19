import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/discover_providers.dart';
import '../domain/discover_entities.dart';
import 'discover_navigation.dart';
import 'widgets/discover_load_more_indicator.dart';
import 'widgets/discover_profile_row.dart';
import 'widgets/discover_repo_row.dart';

/*
 *发现页列表容器:所有窗口宽度均使用单列,保证仓库描述与指标可连续扫读。
 */
Widget _buildDiscoverList({required BuildContext context, required int itemCount, required bool hasMore, required Widget Function(BuildContext, int) itemBuilder}) {
  final compact = Breakpoints.isCompact(context);
  return ListView.separated(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, compact ? AppSpacing.xs : AppSpacing.md, compact ? AppSpacing.lg : AppSpacing.xl, AppSpacing.xxxl),
    itemCount: itemCount + (hasMore ? 1 : 0),
    separatorBuilder: (_, __) => SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
    itemBuilder: (context, i) {
      if (i >= itemCount) {
        return const DiscoverLoadMoreIndicator();
      }
      return itemBuilder(context, i);
    },
  );
}

class DiscoverReposSection extends ConsumerWidget {
  const DiscoverReposSection({required this.async, required this.onRetry, super.key});

  final AsyncValue<List<RepoEntity>> async;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: onRetry,
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return EmptyView(icon: Icons.explore_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.repos') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
        }
        final hasMore = query.trim().isEmpty && ref.read(trendingReposNotifierProvider.notifier).hasMore;
        if (Breakpoints.isCompact(context)) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxxl),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < repos.length; index++) ...[
                      if (index != 0) const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      DiscoverMonitorRow(repo: repos[index], badge: '#${index + 1}', embedded: true, onTap: () => context.go(discoverRepoDetailLocation(repos[index].fullName))),
                    ],
                    if (hasMore) const DiscoverLoadMoreIndicator(),
                  ],
                ),
              ),
            ],
          );
        }
        return _buildDiscoverList(
          context: context,
          itemCount: repos.length,
          hasMore: hasMore,
          itemBuilder: (context, i) => DiscoverMonitorRow(repo: repos[i], onTap: () => context.go(discoverRepoDetailLocation(repos[i].fullName))),
        );
      },
    );
  }
}

class DiscoverSkillsSection extends ConsumerWidget {
  const DiscoverSkillsSection({required this.async, required this.onRetry, super.key});

  final AsyncValue<List<SkillEntity>> async;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: onRetry,
      ),
      data: (skills) {
        if (skills.isEmpty) {
          return EmptyView(icon: Icons.extension_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.skills') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
        }
        final hasMore = query.trim().isEmpty && ref.read(agentSkillsNotifierProvider.notifier).hasMore;
        return _buildDiscoverList(
          context: context,
          itemCount: skills.length,
          hasMore: hasMore,
          itemBuilder: (context, i) =>
              DiscoverMonitorRow(repo: skills[i].repo, badge: '#${skills[i].rank} · ${skills[i].category}', onTap: () => context.go(discoverRepoDetailLocation(skills[i].repo.fullName))),
        );
      },
    );
  }
}

class DiscoverProfilesSection extends ConsumerWidget {
  const DiscoverProfilesSection({required this.provider, required this.emptyIcon, required this.emptyMessage, required this.kind, required this.onRetry, super.key});

  final ProviderListenable<AsyncValue<List<DiscoverProfileEntity>>> provider;
  final IconData emptyIcon;
  final String emptyMessage;
  // null 表示移动端合并官方组织与知名人士。
  final DiscoverProfileKind? kind;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(discoverSearchQueryProvider);
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: onRetry,
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return EmptyView(icon: emptyIcon, message: query.trim().isEmpty ? emptyMessage : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
        }
        final hasMore =
            query.trim().isEmpty &&
            switch (kind) {
              DiscoverProfileKind.official => ref.read(officialProfilesNotifierProvider.notifier).hasMore,
              DiscoverProfileKind.people => ref.read(peopleProfilesNotifierProvider.notifier).hasMore,
              null => ref.read(officialProfilesNotifierProvider.notifier).hasMore || ref.read(peopleProfilesNotifierProvider.notifier).hasMore,
            };
        return _buildDiscoverList(
          context: context,
          itemCount: profiles.length,
          hasMore: hasMore,
          itemBuilder: (context, i) => DiscoverProfileRow(profile: profiles[i], onTap: () => context.go(discoverProfileDetailLocation(profiles[i]))),
        );
      },
    );
  }
}
