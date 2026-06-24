import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/app_locale.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_preset.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/theme/theme_preset_controller.dart';
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
      appBar: AppBar(title: Text(context.t.t('profile.appBar'))),
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
  pro('profile.section.pro', Icons.workspace_premium_outlined),
  collect('profile.section.collect', Icons.bookmark_outline),
  developers('profile.section.developers', Icons.people_outline),
  monitorTopics('profile.section.monitorTopics', Icons.visibility_outlined),
  monitorRules('profile.section.monitorRules', Icons.bolt_rounded),
  data('profile.section.data', Icons.storage_outlined),
  settings('profile.section.settings', Icons.tune),
  about('profile.section.about', Icons.info_outline);

  const _ProfileSection(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;

  /// 区段强调色:跟随当前主题色(主区段)或保留语义色(子区段)。
  Color accentOf(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (this) {
      _ProfileSection.pro ||
      _ProfileSection.monitorTopics ||
      _ProfileSection.settings =>
        colors.primary,
      _ProfileSection.collect || _ProfileSection.data => AppColors.info,
      _ProfileSection.developers => AppColors.success,
      _ProfileSection.monitorRules => AppColors.warning,
      _ProfileSection.about => colors.onSurfaceVariant,
    };
  }
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
            child: Text(
              context.t.t('profile.settings'),
              style: AppTypography.titleMedium,
            ),
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
    final accent = section.accentOf(context);
    final bg = selected ? accent.withValues(alpha: 0.12) : Colors.transparent;
    final fg = selected ? accent : colors.onSurfaceVariant;
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
                context.t.t(section.labelKey),
                style: AppTypography.bodyMedium.copyWith(
                  color: selected ? colors.onSurface : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(Icons.chevron_right, size: 16, color: accent),
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
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: colors.onPrimary,
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
                      t.t('profile.user.nickname'),
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.t('app.pro'),
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.t('profile.user.anonHint'),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.t('profile.user.loginHint'),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.pro.title'),
            subtitle: t.t('profile.pro.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _Bullet(t.t('profile.pro.b1')),
          _Bullet(t.t('profile.pro.b2')),
          _Bullet(t.t('profile.pro.b3')),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: Text(t.t('profile.pro.upgrade')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_outline, color: AppColors.info),
            title: Text(t.t('profile.list.bookmarked'),
                style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/collect'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: AppColors.success),
            title: Text(t.t('profile.list.followed'),
                style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developers'),
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
    final t = context.t;
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(t.t('profile.list.monitorTopics'),
                style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/monitor'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bolt_rounded, color: AppColors.warning),
            title: Text(t.t('profile.list.monitorRules'),
                style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/rules'),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.detail.collectTitle'),
            subtitle: t.t('profile.detail.collectSubtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.bookmark_outline,
            iconColor: AppColors.info,
            label: '${t.t('profile.detail.collectCount')}(12)',
            value: t.t('app.all'),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.history,
            iconColor: AppColors.textSecondaryLight,
            label: t.t('profile.detail.collectRecent'),
            value: 'agent · llm · devops',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/collect'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t.t('profile.detail.open')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.detail.developersTitle'),
            subtitle: t.t('profile.detail.developersSubtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.people_outline,
            iconColor: AppColors.success,
            label: '${t.t('profile.detail.developersCount')}(8)',
            value: t.t('app.all'),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: t.t('profile.detail.developersNotif'),
            value: 'Star / Fork / Release',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/developers'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t.t('profile.detail.developersOpen')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.detail.monitorTopicsTitle'),
            subtitle: t.t('profile.detail.monitorTopicsSubtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.visibility_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            label: '${t.t('profile.detail.monitorTopicsCount')}(5)',
            value: t.t('app.all'),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.timeline,
            iconColor: AppColors.info,
            label: t.t('profile.detail.monitorTopicsLatest'),
            value: t.t('profile.detail.unread2'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/monitor'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t.t('profile.detail.monitorTopicsOpen')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.detail.monitorRulesTitle'),
            subtitle: t.t('profile.detail.monitorRulesSubtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: t.t('profile.detail.monitorRulesRow1'),
            value: t.t('app.enabled'),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: t.t('profile.detail.monitorRulesRow2'),
            value: t.t('app.enabled'),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: t.t('profile.detail.monitorRulesRow3'),
            value: t.t('app.enabled'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/rules'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t.t('profile.detail.monitorRulesManage')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.detail.dataTitle'),
            subtitle: t.t('profile.detail.dataSubtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _DataRow(label: t.t('profile.detail.dataRow1'), value: '12.8 MB'),
          _DataRow(label: t.t('profile.detail.dataRow2'), value: '156 MB'),
          _DataRow(label: t.t('profile.detail.dataRow3'), value: '624 MB'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: Text(t.t('profile.detail.dataClear')),
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
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.settings.title'),
            subtitle: t.t('profile.settings.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ThemeColorRow(),
          const SizedBox(height: AppSpacing.sm),
          _SettingRow(
            icon: Icons.dark_mode_outlined,
            label: t.t('profile.settings.darkMode'),
            trailing: const _ThemeToggle(),
          ),
          _LanguageSwitcher(),
          _SettingRow(
            icon: Icons.notifications_none,
            label: t.t('profile.settings.notificationPerm'),
            trailing: Text(
              t.t('app.enabled'),
              style: AppTypography.labelMedium,
            ),
          ),
          _SettingRow(
            icon: Icons.rocket_launch_outlined,
            label: t.t('profile.settings.startup'),
            trailing: Text(
              t.t('nav.home'),
              style: AppTypography.labelMedium,
            ),
          ),
          _SettingRow(
            icon: Icons.cloud_outlined,
            label: t.t('profile.settings.dataSource'),
            trailing: Text('GitHub', style: AppTypography.labelMedium),
          ),
          _SettingRow(
            icon: Icons.code,
            label: t.t('profile.settings.developerOptions'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developer'),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final current = ref.watch(localeControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.language_outlined,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.t('profile.settings.language'),
              style: AppTypography.bodyMedium,
            ),
          ),
          _LanguageToggle(
            current: current,
            onChanged: (locale) =>
                ref.read(localeControllerProvider.notifier).setLocale(locale),
          ),
        ],
      ),
    );
  }
}

/// 中/英 二选一 toggle 按钮组(单击即切换,无须弹窗)。
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.current, required this.onChanged});

  final AppLocale current;
  final ValueChanged<AppLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(
            label: '中',
            selected: current == AppLocale.zh,
            onTap: () => onChanged(AppLocale.zh),
          ),
          _LanguageChip(
            label: 'EN',
            selected: current == AppLocale.en,
            onTap: () => onChanged(AppLocale.en),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? colors.onSurface : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: t.t('profile.about.title'),
            subtitle: t.t('profile.about.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          _AboutRow(label: t.t('profile.about.version'), value: '0.1.0'),
          _AboutRow(label: t.t('profile.about.build'), value: '2026-06-23'),
          _AboutRow(
              label: t.t('profile.about.website'), value: 'github-news.app'),
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

/// 主题色选择行:展示 10 个色圆,点击切换 seed。
class _ThemeColorRow extends ConsumerWidget {
  const _ThemeColorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final current = ref.watch(themePresetControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.t('theme.presetTitle'),
                  style: AppTypography.bodyMedium,
                ),
              ),
              Text(
                t.t(current.nameKey),
                style: AppTypography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in AppThemePreset.values)
                _ColorSwatch(
                  preset: p,
                  selected: p == current,
                  onTap: () => ref
                      .read(themePresetControllerProvider.notifier)
                      .setPreset(p),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.t('theme.presetSubtitle'),
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.t.t(preset.nameKey),
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: preset.seed,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.onSurface : Colors.transparent,
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: preset.seed.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: selected
              ? Icon(Icons.check, size: 14, color: colors.onPrimary)
              : null,
        ),
      ),
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
