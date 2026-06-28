import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/project_providers.dart';
import 'widgets/project_page_skeleton.dart';

/// 二级:探索发现(话题 → 仓库 → 推荐)。
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/project'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => _buildBody(state, ref),
        medium: (_) => CenteredContent(child: _buildBody(state, ref)),
        expanded: (_) => CenteredContent(child: _buildBody(state, ref)),
      ),
    );
  }

  Widget _buildBody(AsyncValue<ProjectDigest> state, WidgetRef ref) {
    return state.when(
      data: (digest) => digest.isEmpty
          ? const EmptyView(
              icon: Icons.explore_outlined,
              message: '暂无探索内容',
            )
          : _Body(digest: digest),
      loading: () => const ProjectPageSkeleton(),
      error: (error, stack) => ErrorView(
        error: _toAppException(error, stack),
        onRetry: () => ref.invalidate(projectDigestProvider),
      ),
    );
  }

  AppException _toAppException(Object error, StackTrace stack) {
    if (error is AppException) return error;
    return AppException(
      kind: AppExceptionKind.unknown,
      cause: error,
      stack: stack,
    );
  }
}

class _TopicChipSpec {
  const _TopicChipSpec({required this.label, required this.color});
  final String label;
  final Color color;
}

class _Body extends StatelessWidget {
  const _Body({required this.digest});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chips = <_TopicChipSpec>[
      _TopicChipSpec(label: 'AI 智能体', color: colors.primary),
      const _TopicChipSpec(label: '大语言模型', color: AppColors.info),
      const _TopicChipSpec(label: '开发工具', color: AppColors.success),
      const _TopicChipSpec(label: '检索增强生成', color: AppColors.warning),
      const _TopicChipSpec(label: 'Web3', color: AppColors.danger),
      _TopicChipSpec(label: '云原生', color: colors.primary),
      const _TopicChipSpec(label: '数据基建', color: AppColors.info),
      const _TopicChipSpec(label: '安全', color: AppColors.success),
    ];
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
                title: '热门话题',
                subtitle: '基于本周 Star 增速与讨论热度',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in chips)
                    _TopicChip(label: c.label, color: c.color),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
                  title: '推荐仓库',
                  subtitle: '基于你的关注 · 共 ${digest.repos.length} 个',
                ),
              ),
              for (var i = 0; i < digest.repos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: digest.repos[i],
                  onTap: () => context.go(
                    '/repo_detail/${Uri.encodeComponent(digest.repos[i].fullName)}',
                  ),
                ),
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
                title: '可关注的开发者',
                subtitle: '本周 Star 增长贡献 Top 5',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final c in digest.contributors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Color(c.avatarColor).withValues(alpha: 0.16),
                    child: Text(
                      c.login[0].toUpperCase(),
                      style: AppTypography.titleSmall.copyWith(
                        color: Color(c.avatarColor),
                      ),
                    ),
                  ),
                  title: Text(c.login, style: AppTypography.titleSmall),
                  subtitle: Text('+${c.contributions} 本周贡献'),
                  trailing: OutlinedButton(
                    onPressed: () {},
                    child: const Text('关注'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
