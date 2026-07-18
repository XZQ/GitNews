import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';

/*
*移动端设置首页的四个个人内容入口。
*
*设计稿把收藏、关注、监控仓库和监控规则收进同一张分组卡片，计数作为弱化的行尾信息，避免多个大卡片打断浏览节奏。
*/
class ProfileOverviewListCard extends StatelessWidget {
  const ProfileOverviewListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          _OverviewEntry(icon: Icons.bookmark_outline_rounded, iconColor: Theme.of(context).colorScheme.primary, label: l10n.tr('profile.section.collect'), count: '12', route: '/profile/collect'),
          const Divider(height: 1),
          _OverviewEntry(icon: Icons.person_outline_rounded, iconColor: AppColors.success, label: l10n.tr('profile.section.developers'), count: '5', route: '/profile/developers'),
          const Divider(height: 1),
          _OverviewEntry(icon: Icons.adjust_rounded, iconColor: AppColors.info, label: l10n.tr('profile.section.monitor_topics'), count: '7', route: '/profile/monitor'),
          const Divider(height: 1),
          _OverviewEntry(icon: Icons.bolt_rounded, iconColor: AppColors.warning, label: l10n.tr('profile.section.monitor_rules'), count: '3', route: '/profile/rules'),
        ],
      ),
    );
  }
}

/* 单个个人内容入口行。 */
class _OverviewEntry extends StatelessWidget {
  const _OverviewEntry({required this.icon, required this.iconColor, required this.label, required this.count, required this.route});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String count;
  final String route;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(route),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700))),
            Text(count, style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/* 
*手机端聚合卡:收藏 + 关注开发者。
*/
class ProfileCollectListCard extends StatelessWidget {
  const ProfileCollectListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_outline, color: AppColors.info),
            title: Text(l10n.tr('profile.section.collect'), style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/collect'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: AppColors.success),
            title: Text(l10n.tr('profile.section.developers'), style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developers'),
          )
        ],
      ),
    );
  }
}

/* 
*手机端聚合卡:监控主题 + 监控规则。
*/
class ProfileMonitorListCard extends StatelessWidget {
  const ProfileMonitorListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.tr('profile.section.monitor_topics'), style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/monitor'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bolt_rounded, color: AppColors.warning),
            title: Text(l10n.tr('profile.section.monitor_rules'), style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/rules'),
          )
        ],
      ),
    );
  }
}

class ProfileSettingsListCard extends StatelessWidget {
  const ProfileSettingsListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.settings_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          l10n.tr('profile.mobile_settings.title'),
          style: AppTypography.titleMedium,
        ),
        subtitle: Text(l10n.tr('profile.mobile_settings.subtitle')),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => context.go('/profile/preferences'),
      ),
    );
  }
}
