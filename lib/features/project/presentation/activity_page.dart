import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/// 二级:活动速览(Commit / Issue / Release 流)。
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.t('project.activity.title')),
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

class _EventSpec {
  const _EventSpec({
    required this.repo,
    required this.title,
    required this.timeBuilder,
    required this.icon,
    required this.color,
  });

  final String repo;
  final String title;
  final String Function(BuildContext) timeBuilder;
  final IconData icon;
  final Color color;
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final events = <_EventSpec>[
      _EventSpec(
        repo: 'openai/whisper',
        title: 'feat: support streaming response',
        timeBuilder: (_) => context.t
            .tr('time.hoursAgoWithBranch', {'hours': 4, 'branch': 'main'}),
        icon: Icons.commit,
        color: AppColors.success,
      ),
      _EventSpec(
        repo: 'anthropics/claude-code',
        title: 'fix: cache invalidation race',
        timeBuilder: (_) => context.t
            .tr('time.hoursAgoWithBranch', {'hours': 6, 'branch': 'main'}),
        icon: Icons.bug_report_outlined,
        color: AppColors.info,
      ),
      _EventSpec(
        repo: 'denoland/deno',
        title: 'chore: bump dependencies',
        timeBuilder: (_) => context.t.tr(
            'time.yesterdayWithBranch', {'time': '18:24', 'branch': 'main'}),
        icon: Icons.upgrade,
        color: AppColors.warning,
      ),
      _EventSpec(
        repo: 'mrdoob/three.js',
        title: 'release v0.42.1',
        timeBuilder: (_) => context.t.tr('time.daysAgo', {'days': 3}),
        icon: Icons.local_fire_department,
        color: colors.primary,
      ),
      _EventSpec(
        repo: 'withastro/astro',
        title: 'docs: new tutorial',
        timeBuilder: (_) => context.t
            .tr('time.daysAgoWithBranch', {'days': 3, 'branch': 'main'}),
        icon: Icons.description,
        color: AppColors.info,
      ),
      _EventSpec(
        repo: 'vitejs/vite',
        title: 'feat: optimize build pipeline',
        timeBuilder: (_) => context.t.tr('time.daysAgo', {'days': 4}),
        icon: Icons.flash_on,
        color: AppColors.success,
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
                  title: context.t.t('project.activity.recentTitle'),
                  subtitle: context.t.t('project.activity.recentSubtitle'),
                ),
              ),
              for (var i = 0; i < events.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                _EventTile(
                  repo: events[i].repo,
                  title: events[i].title,
                  time: events[i].timeBuilder(context),
                  icon: events[i].icon,
                  color: events[i].color,
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
                title: context.t.t('project.activity.developersTitle'),
                subtitle: context.t.t('project.activity.developersSubtitle'),
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
              ),
          ]),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.repo,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String repo;
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go('/repo_detail/${Uri.encodeComponent(repo)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo, style: AppTypography.titleSmall),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
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
