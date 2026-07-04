import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';

/// 二级页 3:热门仓库(完整列表 + 表格视图)。
class HotReposPage extends ConsumerWidget {
  const HotReposPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredTrendingDigestProvider);
    final searchQuery = ref.watch(trendingSearchQueryProvider).trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('热门仓库'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trending'),
        ),
      ),
      body: state.when(
        data: (digest) {
          if (digest.allRepos.isEmpty) {
            return EmptyView(
              icon: searchQuery.isEmpty
                  ? Icons.local_fire_department_outlined
                  : Icons.search_off_rounded,
              message:
                  searchQuery.isEmpty ? '暂无热门仓库' : '未找到与「$searchQuery」相关的仓库',
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
    final repos = digest.allRepos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
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
                  title: '热门仓库 · 完整列表',
                  subtitle: '按 Star 增速排序 · 共 ${repos.length} 个',
                ),
              ),
              for (var i = 0; i < repos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: repos[i],
                  onTap: () => context.go(
                    '/trending/detail/${Uri.encodeComponent(repos[i].fullName)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '说明',
                subtitle: '数据来源与刷新策略',
              ),
              SizedBox(height: AppSpacing.sm),
              _Bullet('GitHub Trending 与社区聚合 · 每 5 分钟刷新'),
              _Bullet('Star 增速以最近 24h 为基准 · 含历史对比'),
              _Bullet('点击仓库进入详情页,查看 30 天 Star 历史'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs2,
              right: AppSpacing.sm,
            ),
            child: Container(
              width: AppSpacing.xs2,
              height: AppSpacing.xs2,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(AppRadius.bar),
              ),
            ),
          ),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
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
          Skeleton(height: 280),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 120),
        ],
      ),
    );
  }
}
