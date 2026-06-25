import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';

/// 二级:发现推荐(收藏夹 + 热门仓库推荐)。
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(child: _Body()),
        expanded: (_) => const CenteredContent(child: _Body()),
      ),
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
  const _Body();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topics = <_TopicSpec>[
      _TopicSpec(label: 'AI 智能体', count: 32, color: colors.primary),
      const _TopicSpec(label: '大语言模型', count: 128, color: AppColors.info),
      const _TopicSpec(label: '开发工具', count: 64, color: AppColors.success),
      const _TopicSpec(label: '检索增强生成', count: 24, color: AppColors.warning),
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '热门主题',
                subtitle: '基于你的关注和浏览历史',
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in topics)
                  _TopicCard(
                    label: t.label,
                    desc: '${t.count} 个仓库',
                    color: t.color,
                  ),
              ],
            ),
          ]),
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
              for (var i = 0; i < DemoData.trending.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: DemoData.trending[i],
                  onTap: () => context.go(
                    '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '推荐开发者',
                subtitle: '你应该关注的活跃贡献者',
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            for (final c in DemoData.contributors)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(c.avatarColor).withValues(alpha: 0.16),
                  child: Text(
                    c.login[0].toUpperCase(),
                    style: AppTypography.titleSmall.copyWith(
                      color: Color(c.avatarColor),
                    ),
                  ),
                ),
                title: Text(c.login, style: AppTypography.titleSmall),
                subtitle: Text(
                  '+${c.contributions} 本周贡献',
                ),
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: const Text('关注'),
                ),
              ),
          ]),
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
          const SizedBox(height: 4),
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

extension _ColumnCopy on Column {
  Column copyChildren(List<Widget> extra) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      children: [...children, ...extra],
    );
  }
}
