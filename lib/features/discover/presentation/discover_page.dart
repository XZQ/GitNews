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
import '../../../shared/widgets/page_header.dart';
import '../application/discover_providers.dart';
import '../domain/discover_entities.dart';
import 'widgets/discover_repo_row.dart';
import 'widgets/discover_segmented.dart';

/// 发现页:流行仓库 Top20 + Agent Skills 榜,行尾一键加/移监控。
class DiscoverHubPage extends ConsumerStatefulWidget {
  const DiscoverHubPage({super.key});

  @override
  ConsumerState<DiscoverHubPage> createState() => _DiscoverHubPageState();
}

class _DiscoverHubPageState extends ConsumerState<DiscoverHubPage> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      ref.read(discoverRefreshTickProvider.notifier).state++;
      ref.invalidate(trendingReposProvider);
      ref.invalidate(agentSkillsProvider);
      final skills = ref.read(discoverSegmentProvider) == 'skills';
      if (skills) {
        await ref.read(filteredAgentSkillsProvider.future);
      } else {
        await ref.read(filteredTrendingReposProvider.future);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isCompact = Breakpoints.isCompact(context);
    final segment = ref.watch(discoverSegmentProvider);
    final query = ref.watch(discoverSearchQueryProvider);
    final reposAsync = ref.watch(filteredTrendingReposProvider);
    final skillsAsync = ref.watch(filteredAgentSkillsProvider);

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
            onSearchChanged: (v) =>
                ref.read(discoverSearchQueryProvider.notifier).state = v,
            onRefresh: _refresh,
            isRefreshing: _refreshing,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DiscoverSegmented(
                value: segment,
                onChanged: (v) =>
                    ref.read(discoverSegmentProvider.notifier).state = v,
              ),
            ),
          ),
          Expanded(
            child: segment == 'skills'
                ? _buildSkills(skillsAsync, l10n)
                : _buildRepos(reposAsync, l10n),
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
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException
            ? e
            : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return EmptyView(
            icon: Icons.explore_off_outlined,
            message: query.trim().isEmpty
                ? l10n.tr('discover.empty.repos')
                : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: repos.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => DiscoverMonitorRow(
            repo: repos[i],
            onTap: () => context.go(
              '/discover/detail/${Uri.encodeComponent(repos[i].fullName)}',
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkills(
    AsyncValue<List<SkillEntity>> async,
    AppLocalizations l10n,
  ) {
    final query = ref.watch(discoverSearchQueryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException
            ? e
            : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (skills) {
        if (skills.isEmpty) {
          return EmptyView(
            icon: Icons.extension_off_outlined,
            message: query.trim().isEmpty
                ? l10n.tr('discover.empty.skills')
                : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: skills.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => DiscoverMonitorRow(
            repo: skills[i].repo,
            badge: '#${skills[i].rank} · ${skills[i].category}',
            onTap: () => context.go(
              '/discover/detail/${Uri.encodeComponent(skills[i].repo.fullName)}',
            ),
          ),
        );
      },
    );
  }
}
