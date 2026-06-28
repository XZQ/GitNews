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

/// 二级:发现推荐(收藏夹 + 热门仓库推荐)。
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现推荐'),
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
              icon: Icons.lightbulb_outline_rounded,
              message: '暂无推荐内容',
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

class _TopicSpec {
  const _TopicSpec({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _Body extends StatelessWidget {
  const _Body({required this.digest});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topics = <_TopicSpec>[
      _TopicSpec(label: 'AI 智能体', count: 32, color: colors.primary),
      const _TopicSpec(label: '大语言模型', count: 128, color: AppColors.info),
      const _TopicSpec(label: '开发工具', count: 64, color: AppColors.success),
      const _TopicSpec(
        label: '检索增强生成',
        count: 24,
        color: AppColors.warning,
      ),
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
                title: '热门主题',
                subtitle: '基于你的关注和浏览历史',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final t in topics)
                    _TopicCard(
                      label: t.label,
                      desc: '${t.count} 个仓库',
                      color: t.color,
                    ),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '推荐仓库',
                  subtitle: '与你的兴趣最相关的项目',
                ),
              ),
              for (var i = 0; i < digest.repos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: digest.repos[i],
                  onTap: () => context.go(
                    '/project/detail/${Uri.encodeComponent(digest.repos[i].fullName)}',
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
                title: '推荐开发者',
                subtitle: '你应该关注的活跃贡献者',
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已关注 @${c.login}')),
                      );
                    },
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.label,
    required this.desc,
    required this.color,
  });
  final String label;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            desc,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
