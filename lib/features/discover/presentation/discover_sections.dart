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

/*
 *发现页列表容器:桌面端(≥1024)一行 2 项,其余单列卡片。
 *
 *桌面端两列通过把相邻两项包进同一 `Row` 实现,行高由较高的项决定,
 *避免 GridView 强制 aspectRatio 带来的描述文字裁切。
 */
Widget _buildDiscoverList({
  required BuildContext context,
  required ScrollController scrollController,
  required int itemCount,
  required bool hasMore,
  required Widget Function(BuildContext, int) itemBuilder,
}) {
  final twoColumn = Breakpoints.isExpanded(context);
  final cardPadding = const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl);
  if (twoColumn) {
    final rowCount = (itemCount + 1) ~/ 2;
    return ListView.separated(
        controller: scrollController,
        padding: cardPadding,
        itemCount: rowCount + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, row) {
          if (row >= rowCount) {
            return const DiscoverLoadMoreIndicator();
          }
          final i1 = row * 2;
          final i2 = i1 + 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: itemBuilder(context, i1)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: i2 < itemCount ? itemBuilder(context, i2) : const SizedBox()),
          ]);
        });
  }
  // 单列(手机 / 平板):统一卡片式条目,与监控页、趋势页移动端保持一致。
  return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      itemCount: itemCount + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (i >= itemCount) {
          return const DiscoverLoadMoreIndicator();
        }
        return itemBuilder(context, i);
      });
}

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
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e), onRetry: onRetry),
        data: (repos) {
          if (repos.isEmpty) {
            return EmptyView(icon: Icons.explore_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.repos') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
          }
          final hasMore = query.trim().isEmpty && ref.read(trendingReposNotifierProvider.notifier).hasMore;
          return _buildDiscoverList(
            context: context,
            scrollController: scrollController,
            itemCount: repos.length,
            hasMore: hasMore,
            itemBuilder: (context, i) => DiscoverMonitorRow(repo: repos[i], onTap: () => context.go(discoverRepoDetailLocation(repos[i].fullName))),
          );
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
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e), onRetry: onRetry),
        data: (skills) {
          if (skills.isEmpty) {
            return EmptyView(icon: Icons.extension_off_outlined, message: query.trim().isEmpty ? l10n.tr('discover.empty.skills') : l10n.tr('discover.empty_filter').replaceAll('{query}', query));
          }
          final hasMore = query.trim().isEmpty && ref.read(agentSkillsNotifierProvider.notifier).hasMore;
          return _buildDiscoverList(
            context: context,
            scrollController: scrollController,
            itemCount: skills.length,
            hasMore: hasMore,
            itemBuilder: (context, i) => DiscoverMonitorRow(
              repo: skills[i].repo,
              badge: '#${skills[i].rank} · ${skills[i].category}',
              onTap: () => context.go(discoverRepoDetailLocation(skills[i].repo.fullName)),
            ),
          );
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
          return _buildDiscoverList(
            context: context,
            scrollController: scrollController,
            itemCount: profiles.length,
            hasMore: hasMore,
            itemBuilder: (context, i) => DiscoverProfileRow(profile: profiles[i], onTap: () => context.go(discoverProfileDetailLocation(profiles[i]))),
          );
        });
  }
}
