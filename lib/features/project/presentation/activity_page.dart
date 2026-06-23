import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
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
        title: const Text('活动速览'),
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

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final events = const [
      (
        'openai/whisper',
        'feat: support streaming response',
        '4 小时前 · main',
        Icons.commit,
        AppColors.success
      ),
      (
        'anthropics/claude-code',
        'fix: cache invalidation race',
        '6 小时前 · main',
        Icons.bug_report_outlined,
        AppColors.info
      ),
      (
        'denoland/deno',
        'chore: bump dependencies',
        '昨天 18:24 · main',
        Icons.upgrade,
        AppColors.warning
      ),
      (
        'mrdoob/three.js',
        'release v0.42.1',
        '3 天前',
        Icons.local_fire_department,
        AppColors.brand
      ),
      (
        'withastro/astro',
        'docs: new tutorial',
        '3 天前 · main',
        Icons.description,
        AppColors.info
      ),
      (
        'vitejs/vite',
        'feat: optimize build pipeline',
        '4 天前',
        Icons.flash_on,
        AppColors.success
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
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '近 7 天活动',
                  subtitle: '跨仓库的 Commit / Issue / Release',
                ),
              ),
              for (var i = 0; i < events.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                _EventTile(
                  repo: events[i].$1,
                  title: events[i].$2,
                  time: events[i].$3,
                  icon: events[i].$4,
                  color: events[i].$5,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(
                title: '可能感兴趣的开发者',
                subtitle: '近 7 天活跃',
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
                subtitle: Text('+${c.contributions} 本周贡献'),
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
