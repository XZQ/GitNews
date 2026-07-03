import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class RepoDetailActivity extends StatelessWidget {
  const RepoDetailActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ActivityItem>[
      const _ActivityItem(
        title: 'feat: support streaming response',
        time: '4 小时前 · main',
        color: AppColors.success,
        icon: Icons.commit,
      ),
      const _ActivityItem(
        title: 'fix: cache invalidation race',
        time: '6 小时前 · main',
        color: AppColors.info,
        icon: Icons.bug_report_outlined,
      ),
      const _ActivityItem(
        title: 'chore: bump dependencies',
        time: '昨天 18:24 · main',
        color: AppColors.warning,
        icon: Icons.upgrade,
      ),
      _ActivityItem(
        title: 'release v0.42.1',
        time: '3 天前',
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.local_fire_department,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('repo_detail.section.activity'),
            subtitle: l10n.tr('repo_detail.section.activity.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final i in items) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(i.icon, color: i.color, size: 18),
                  ),
                  title: Text(i.title, style: AppTypography.titleSmall),
                  subtitle: Text(i.time, style: AppTypography.labelSmall),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.time,
    required this.color,
    required this.icon,
  });

  final String title;
  final String time;
  final Color color;
  final IconData icon;
}
