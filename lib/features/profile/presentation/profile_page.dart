import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/// "我的"页面:
/// - 手机/平板:卡片纵向堆叠(单列)。
/// - 桌面:左侧设置项列表,右侧选中项的详情卡片。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: ResponsiveLayout(
        compact: (_) => const _Mobile(),
        medium: (_) => const _Mobile(),
        expanded: (_) => const _Desktop(),
      ),
    );
  }
}

/// 桌面端 master-detail 区段。
enum _ProfileSection {
  pro('Upgrade PRO', Icons.workspace_premium_outlined, AppColors.brand),
  collect('Bookmarked Topics', Icons.bookmark_outline, AppColors.info),
  developers('Followed Developers', Icons.people_outline, AppColors.success),
  monitorTopics('Monitored Topics', Icons.visibility_outlined, AppColors.brand),
  monitorRules('Monitor Rules', Icons.bolt_rounded, AppColors.warning),
  data('Data & Cache', Icons.storage_outlined, AppColors.info),
  settings('Preferences', Icons.tune, AppColors.brand),
  about('About', Icons.info_outline, AppColors.textSecondaryLight);

  const _ProfileSection(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

/// 当前选中的桌面区段。NotFound → 默认 settings。
final _selectedSectionProvider =
    StateProvider<_ProfileSection>((ref) => _ProfileSection.settings);

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        _UserCard(),
        SizedBox(height: AppSpacing.lg),
        _ProCard(),
        SizedBox(height: AppSpacing.lg),
        _CollectListCard(),
        SizedBox(height: AppSpacing.lg),
        _MonitorListCard(),
        SizedBox(height: AppSpacing.lg),
        _DataCard(),
        SizedBox(height: AppSpacing.lg),
        _SettingsCard(),
        SizedBox(height: AppSpacing.lg),
        _AboutCard(),
      ],
    );
  }
}

class _Desktop extends ConsumerWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedSectionProvider);
    final isCompact = Breakpoints.isCompact(context);
    final maxWidth = isCompact ? 960.0 : 1120.0;

    return CenteredContent(
      maxWidth: maxWidth,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          const _UserCard(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _SectionList(selected: selected),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 6,
                child: _SectionDetail(section: selected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionList extends ConsumerWidget {
  const _SectionList({required this.selected});

  final _ProfileSection selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('Settings', style: AppTypography.titleMedium),
          ),
          const Divider(height: 1),
          for (final s in _ProfileSection.values)
            _SectionListItem(
              section: s,
              selected: s == selected,
              onTap: () =>
                  ref.read(_selectedSectionProvider.notifier).state = s,
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SectionListItem extends StatelessWidget {
  const _SectionListItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _ProfileSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg =
        selected ? section.accent.withValues(alpha: 0.12) : Colors.transparent;
    final fg = selected ? section.accent : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(section.icon, size: 18, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: selected ? colors.onSurface : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.chevron_right, size: 16, color: section.accent),
          ],
        ),
      ),
    );
  }
}

class _SectionDetail extends StatelessWidget {
  const _SectionDetail({required this.section});

  final _ProfileSection section;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (section) {
      _ProfileSection.pro => const _ProCard(),
      _ProfileSection.collect => const _CollectDetailCard(),
      _ProfileSection.developers => const _DevelopersDetailCard(),
      _ProfileSection.monitorTopics => const _MonitorTopicsDetailCard(),
      _ProfileSection.monitorRules => const _MonitorRulesDetailCard(),
      _ProfileSection.data => const _DataCard(),
      _ProfileSection.settings => const _SettingsCard(),
      _ProfileSection.about => const _AboutCard(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey<_ProfileSection>(section),
        child: body,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'dev_explorer',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Anonymous · sign in to sync data',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign-in is in the sidebar footer',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'GitHub Intelligence PRO',
            subtitle: 'Unlock all premium features',
          ),
          const SizedBox(height: AppSpacing.md),
          const _Bullet('Unlimited monitored repositories'),
          const _Bullet('Advanced alerts & daily reports'),
          const _Bullet('GitHub & Gitee data export'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: const Text('Upgrade PRO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectListCard extends StatelessWidget {
  const _CollectListCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_outline, color: AppColors.info),
            title: const Text('Bookmarked Topics', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/configuration/collect'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: AppColors.success),
            title: const Text('Followed Developers', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/configuration/developers'),
          ),
        ],
      ),
    );
  }
}

class _MonitorListCard extends StatelessWidget {
  const _MonitorListCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.visibility_outlined, color: AppColors.brand),
            title: const Text('Monitored Topics', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/configuration/monitor'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bolt_rounded, color: AppColors.warning),
            title: const Text('Monitor Rules', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/configuration/rules'),
          ),
        ],
      ),
    );
  }
}

class _CollectDetailCard extends StatelessWidget {
  const _CollectDetailCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Bookmarked Topics',
            subtitle: 'GitHub topics you track long-term',
          ),
          const SizedBox(height: AppSpacing.md),
          const _DetailRow(
            icon: Icons.bookmark_outline,
            iconColor: AppColors.info,
            label: 'Bookmarked (12)',
            value: 'View all',
          ),
          const Divider(height: 1),
          const _DetailRow(
            icon: Icons.history,
            iconColor: AppColors.textSecondaryLight,
            label: 'Recent',
            value: 'agent · llm · devops',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/configuration/collect'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Bookmarks'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevelopersDetailCard extends StatelessWidget {
  const _DevelopersDetailCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Followed Developers',
            subtitle: 'Get their latest activity first',
          ),
          const SizedBox(height: AppSpacing.md),
          const _DetailRow(
            icon: Icons.people_outline,
            iconColor: AppColors.success,
            label: 'Followed (8)',
            value: 'View all',
          ),
          const Divider(height: 1),
          const _DetailRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: 'Notification policy',
            value: 'Star / Fork / Release',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/configuration/developers'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Developers'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorTopicsDetailCard extends StatelessWidget {
  const _MonitorTopicsDetailCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Monitored Topics',
            subtitle: 'Track Star / Issue / Release continuously',
          ),
          const SizedBox(height: AppSpacing.md),
          const _DetailRow(
            icon: Icons.visibility_outlined,
            iconColor: AppColors.brand,
            label: 'Monitoring (5)',
            value: 'View all',
          ),
          const Divider(height: 1),
          const _DetailRow(
            icon: Icons.timeline,
            iconColor: AppColors.info,
            label: 'Recent alerts',
            value: '2 unread',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/configuration/monitor'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Monitored Topics'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorRulesDetailCard extends StatelessWidget {
  const _MonitorRulesDetailCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Monitor Rules',
            subtitle: 'Custom alert trigger conditions',
          ),
          const SizedBox(height: AppSpacing.md),
          const _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Star velocity ≥ 30 / day',
            value: 'On',
          ),
          const Divider(height: 1),
          const _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Issue count / hour ≥ 5',
            value: 'On',
          ),
          const Divider(height: 1),
          const _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'New Release',
            value: 'On',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/configuration/rules'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Manage Rules'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Data & Cache', subtitle: 'Local data management'),
          const SizedBox(height: AppSpacing.md),
          const _DataRow(label: 'Topics (2 min refresh)', value: '12.8 MB'),
          const _DataRow(label: 'Topics (7 days)', value: '156 MB'),
          const _DataRow(label: 'Topics (30 days)', value: '624 MB'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('Clear Cache'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Preferences', subtitle: 'Theme / Notification / Startup'),
          const SizedBox(height: AppSpacing.md),
          _SettingRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            trailing: const _ThemeToggle(),
          ),
          _SettingRow(
            icon: Icons.language_outlined,
            label: 'Theme',
            trailing: Text('Follow system', style: AppTypography.labelMedium),
          ),
          _SettingRow(
            icon: Icons.notifications_none,
            label: 'Notifications',
            trailing: Text('Enabled', style: AppTypography.labelMedium),
          ),
          _SettingRow(
            icon: Icons.rocket_launch_outlined,
            label: 'Startup Tab',
            trailing: Text('Overview', style: AppTypography.labelMedium),
          ),
          _SettingRow(
            icon: Icons.cloud_outlined,
            label: 'Data Source',
            trailing: Text('GitHub', style: AppTypography.labelMedium),
          ),
          _SettingRow(
            icon: Icons.code,
            label: 'Developer Options',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/configuration/developer'),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'About', subtitle: 'GitHub developer intelligence'),
          const SizedBox(height: AppSpacing.md),
          const _AboutRow(label: 'Version', value: '0.1.0'),
          const _AboutRow(label: 'Build', value: '2026-06-23'),
          const _AboutRow(label: 'Website', value: 'github-news.app'),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    return Switch(
      value: mode == ThemeMode.dark,
      onChanged: (_) => ref.read(themeModeControllerProvider.notifier).toggle(),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
