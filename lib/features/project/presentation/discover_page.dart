import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/i18n/app_localizations.dart';
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
        title: Text(context.t.t('project.discover.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/project'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => CenteredContent(child: const _Body()),
        expanded: (_) => CenteredContent(child: const _Body()),
      ),
    );
  }
}

class _TopicSpec {
  const _TopicSpec({
    required this.labelKey,
    required this.count,
    required this.color,
  });

  final String labelKey;
  final int count;
  final Color color;
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topics = <_TopicSpec>[
      _TopicSpec(
          labelKey: 'project.topic.aiAgent', count: 32, color: colors.primary),
      _TopicSpec(
          labelKey: 'project.topic.llm', count: 128, color: AppColors.info),
      _TopicSpec(
          labelKey: 'project.topic.devTools',
          count: 64,
          color: AppColors.success),
      _TopicSpec(
          labelKey: 'project.topic.rag', count: 24, color: AppColors.warning),
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
              SectionHeader(
                title: context.t.t('project.discover.hotTitle'),
                subtitle: context.t.t('project.discover.hotSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in topics)
                  _TopicCard(
                    label: context.t.t(t.labelKey),
                    desc: context.t.tr(
                        'project.discover.reposCountFull', {'count': t.count}),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: context.t.t('project.discover.recommendTitle'),
                  subtitle: context.t.t('project.discover.recommendSubtitle'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('project.discover.devsTitle'),
                subtitle: context.t.t('project.discover.devsSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
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
                  context.t.tr('developers.weeklyContribWithCount',
                      {'count': c.contributions}),
                ),
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: Text(context.t.t('project.discover.follow')),
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
