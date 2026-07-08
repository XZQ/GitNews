import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

/* 演示用活动事件规格（离线优先：无真实数据流时展示样例）。 */
class _EventSpec {
  const _EventSpec({
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
}

/* 活动速览卡片：展示近 7 天 Commit / Issue / Release / 文档等样例事件。 */
class ActivityEventsCard extends StatelessWidget {
  const ActivityEventsCard({super.key});

  static const List<_EventSpec> _events = [
    _EventSpec(
      repo: 'openai/whisper',
      title: 'feat: support streaming response',
      time: '4 小时前 · main',
      icon: Icons.commit,
      color: AppColors.success,
    ),
    _EventSpec(
      repo: 'anthropics/claude-code',
      title: 'fix: cache invalidation race',
      time: '6 小时前 · main',
      icon: Icons.bug_report_outlined,
      color: AppColors.info,
    ),
    _EventSpec(
      repo: 'denoland/deno',
      title: 'chore: bump dependencies',
      time: '昨天 18:24 · main',
      icon: Icons.upgrade,
      color: AppColors.warning,
    ),
    _EventSpec(
      repo: 'mrdoob/three.js',
      title: 'release v0.42.1',
      time: '3 天前',
      icon: Icons.local_fire_department,
      color: AppColors.brand,
    ),
    _EventSpec(
      repo: 'withastro/astro',
      title: 'docs: new tutorial',
      time: '3 天前 · main',
      icon: Icons.description,
      color: AppColors.info,
    ),
    _EventSpec(
      repo: 'vitejs/vite',
      title: 'feat: optimize build pipeline',
      time: '4 天前',
      icon: Icons.flash_on,
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
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
            child: Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: l10n.tr('project.activity.recent_7d'),
                    subtitle: l10n.tr('project.activity.recent_7d.subtitle'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Chip(
                  label: Text(l10n.tr('project.activity.demo')),
                  visualDensity: VisualDensity.compact,
                  labelStyle: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
          for (var i = 0; i < _events.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _EventTile(
              repo: _events[i].repo,
              title: _events[i].title,
              time: _events[i].time,
              icon: _events[i].icon,
              color: _events[i].color,
            ),
          ],
        ],
      ),
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
      onTap: () => context.go('/project/detail/${Uri.encodeComponent(repo)}'),
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
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
