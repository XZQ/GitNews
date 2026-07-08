import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/link_open_mode_controller.dart';
import '../../../../core/preferences/locale_controller.dart';
import '../../../../core/preferences/startup_tab_controller.dart';
import '../../../../core/preferences/trending_data_source_mode_controller.dart';
import '../../../../core/router/route_specs.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_preset.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/theme_preset_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileSettingsCard extends ConsumerWidget {
  const ProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.settings.title'),
            subtitle: l10n.tr('profile.settings.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ThemeColorRow(),
          const SizedBox(height: AppSpacing.sm),
          ProfileSettingRow(
            icon: Icons.dark_mode_outlined,
            label: l10n.tr('profile.settings.dark_mode'),
            trailing: const _ThemeToggle(),
          ),
          ProfileSettingRow(
            icon: Icons.translate_outlined,
            label: l10n.tr('app.language'),
            trailing: const _LanguagePicker(),
          ),
          ProfileSettingRow(
            icon: Icons.notifications_none,
            label: l10n.tr('profile.settings.notification'),
            trailing: Text(
              l10n.tr('profile.settings.notification.enabled'),
              style: AppTypography.labelMedium,
            ),
            onTap: () => context.go('/monitor/settings'),
          ),
          ProfileSettingRow(
            icon: Icons.rocket_launch_outlined,
            label: l10n.tr('profile.settings.launch_theme'),
            trailing: const _StartupTabDropdown(),
          ),
          ProfileSettingRow(
            icon: Icons.cloud_outlined,
            label: l10n.tr('profile.settings.data_source'),
            trailing: const _TrendingDataSourceToggle(),
          ),
          ProfileSettingRow(
            icon: Icons.open_in_new_rounded,
            label: l10n.tr('profile.link_open_mode'),
            trailing: const _LinkOpenModeToggle(),
          ),
          ProfileSettingRow(
            icon: Icons.code,
            label: l10n.tr('profile.developer_options'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developer'),
          ),
        ],
      ),
    );
  }
}

/* 
*GitHub 热榜数据源切换:本地模拟 ↔ GitHub Search。
*/
class _TrendingDataSourceToggle extends ConsumerWidget {
  const _TrendingDataSourceToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(trendingDataSourceModeControllerProvider);
    return SegmentedButton<TrendingDataSourceMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -3, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment(
          value: TrendingDataSourceMode.local,
          icon: const Icon(Icons.storage_rounded, size: 14),
          label: Text(l10n.tr('profile.settings.data_source.local')),
        ),
        ButtonSegment(
          value: TrendingDataSourceMode.github,
          icon: const Icon(Icons.cloud_outlined, size: 14),
          label: Text(l10n.tr('profile.settings.data_source.github')),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) {
        ref
            .read(trendingDataSourceModeControllerProvider.notifier)
            .setMode(selection.first);
      },
      showSelectedIcon: false,
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

/*
*应用语言切换:简体中文 ↔ English。
*变更后整 App 重建,UI 立即反映新语言。
*/
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  // UI 列出的语言集合。每个选项对应一个 [LocaleController] 内部持久化值。
  static const _options = <Locale>[Locale('zh', 'CN'), Locale('en', 'US')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    return SegmentedButton<Locale>(
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -3, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final option in _options)
          ButtonSegment(
            value: option,
            icon: const Icon(Icons.translate_rounded, size: 14),
            label: Text(l10n.tr(_labelKeyFor(option))),
          ),
      ],
      selected: {current},
      onSelectionChanged: (selection) {
        ref.read(localeControllerProvider.notifier).setLocale(selection.first);
      },
      showSelectedIcon: false,
    );
  }

  /*
  *将 [Locale] 映射到对应的 i18n key,文本从 `app.language.<code>` 取。
  *未知 locale 回落到 zh-CN 标签。
  */
  String _labelKeyFor(Locale option) {
    final code = option.countryCode ?? '';
    if (code == 'CN') {
      return 'app.language.zh_cn';
    }
    if (code == 'US') {
      return 'app.language.en_us';
    }
    return 'app.language.zh_cn';
  }
}

/*
*链接打开方式切换:应用内 WebView ↔ 系统浏览器。
*/
class _LinkOpenModeToggle extends ConsumerWidget {
  const _LinkOpenModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(linkOpenModeControllerProvider);
    return SegmentedButton<LinkOpenMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -3, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment(
          value: LinkOpenMode.inApp,
          icon: const Icon(Icons.apps_outlined, size: 14),
          label: Text(l10n.tr(LinkOpenMode.inApp.label)),
        ),
        ButtonSegment(
          value: LinkOpenMode.external,
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: Text(l10n.tr(LinkOpenMode.external.label)),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) =>
          ref.read(linkOpenModeControllerProvider.notifier).setMode(s.first),
      showSelectedIcon: false,
    );
  }
}

/* 
*主题色选择行:展示色圆,点击切换 seed。
*/
class _ThemeColorRow extends ConsumerWidget {
  const _ThemeColorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(themePresetControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.tr('profile.settings.theme_color'),
                  style: AppTypography.bodyMedium,
                ),
              ),
              Text(
                current.name,
                style: AppTypography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm2),
          Wrap(
            spacing: AppSpacing.sm2,
            runSpacing: AppSpacing.sm2,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tr('profile.settings.theme_color.hint'),
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
      label: preset.name,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
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
              ),
              alignment: Alignment.center,
              child: selected
                  ? Icon(Icons.check, size: 14, color: colors.onPrimary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 启动 Tab 选择:下拉切换冷启动时落到哪个一级 Tab(下次启动生效)。
class _StartupTabDropdown extends ConsumerWidget {
  const _StartupTabDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(startupTabControllerProvider);
    return DropdownButton<String>(
      value: current,
      underline: const SizedBox.shrink(),
      isDense: true,
      style: AppTypography.labelMedium,
      items: [
        for (final tab in appTabs)
          DropdownMenuItem(
            value: tab.pathSegment,
            child: Text(l10n.tr(tab.labelKey)),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          ref.read(startupTabControllerProvider.notifier).setSegment(value);
        }
      },
    );
  }
}
