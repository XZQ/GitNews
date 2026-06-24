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

/// 二级:探索发现(话题 → 仓库 → 推荐)。
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.t('project.explore.title')),
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

class _TopicChipSpec {
  const _TopicChipSpec({required this.labelKey, required this.color});
  final String labelKey;
  final Color color;
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chips = <_TopicChipSpec>[
      _TopicChipSpec(labelKey: 'project.topic.aiAgent', color: colors.primary),
      _TopicChipSpec(labelKey: 'project.topic.llm', color: AppColors.info),
      _TopicChipSpec(
          labelKey: 'project.topic.devTools', color: AppColors.success),
      _TopicChipSpec(labelKey: 'project.topic.rag', color: AppColors.warning),
      _TopicChipSpec(labelKey: 'project.topic.web3', color: AppColors.danger),
      _TopicChipSpec(
          labelKey: 'project.topic.cloudNative', color: colors.primary),
      _TopicChipSpec(
          labelKey: 'project.topic.dataInfra', color: AppColors.info),
      _TopicChipSpec(
          labelKey: 'project.topic.security', color: AppColors.success),
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
                title: context.t.t('project.explore.hotTopicsTitle'),
                subtitle: context.t.t('project.explore.hotTopicsSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in chips)
                  _TopicChip(
                    label: context.t.t(c.labelKey),
                    color: c.color,
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
                  title: context.t.t('project.explore.recommendTitle'),
                  subtitle: context.t.tr(
                      'project.explore.recommendSubtitleFull',
                      {'count': DemoData.trending.length}),
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
                title: context.t.t('project.explore.developersTitle'),
                subtitle: context.t.t('project.explore.developersSubtitle'),
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
                  child: Text(context.t.t('project.explore.follow')),
                ),
              ),
          ]),
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
