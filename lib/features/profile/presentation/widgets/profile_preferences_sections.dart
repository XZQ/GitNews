import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class TrendingDataSourcePreference extends ConsumerWidget {
  const TrendingDataSourcePreference({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(trendingDataSourceModeControllerProvider);
    return SegmentedButton<TrendingDataSourceMode>(
      style: _compactStyle,
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
        )
      ],
      selected: {mode},
      onSelectionChanged: (selection) => ref.read(trendingDataSourceModeControllerProvider.notifier).setMode(selection.first),
      showSelectedIcon: false,
    );
  }
}

class ThemeModePreference extends ConsumerWidget {
  const ThemeModePreference({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    return Switch(value: mode == ThemeMode.dark, onChanged: (_) => ref.read(themeModeControllerProvider.notifier).toggle());
  }
}

class LanguagePreference extends ConsumerWidget {
  const LanguagePreference({super.key});

  static const _options = <Locale>[Locale('zh', 'CN'), Locale('en', 'US')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    return SegmentedButton<Locale>(
      style: _compactStyle,
      segments: [
        for (final option in _options)
          ButtonSegment(
            value: option,
            icon: const Icon(Icons.translate_rounded, size: 14),
            label: Text(l10n.tr(_labelKeyFor(option))),
          )
      ],
      selected: {current},
      onSelectionChanged: (selection) => ref.read(localeControllerProvider.notifier).setLocale(selection.first),
      showSelectedIcon: false,
    );
  }

  String _labelKeyFor(Locale option) {
    return option.countryCode == 'US' ? 'app.language.en_us' : 'app.language.zh_cn';
  }
}

class LinkOpenModePreference extends ConsumerWidget {
  const LinkOpenModePreference({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(linkOpenModeControllerProvider);
    return SegmentedButton<LinkOpenMode>(
      style: _compactStyle,
      segments: [
        ButtonSegment(value: LinkOpenMode.inApp, icon: const Icon(Icons.apps_outlined, size: 14), label: Text(l10n.tr(LinkOpenMode.inApp.label))),
        ButtonSegment(value: LinkOpenMode.external, icon: const Icon(Icons.open_in_new_rounded, size: 14), label: Text(l10n.tr(LinkOpenMode.external.label)))
      ],
      selected: {mode},
      onSelectionChanged: (selection) => ref.read(linkOpenModeControllerProvider.notifier).setMode(selection.first),
      showSelectedIcon: false,
    );
  }
}

class ThemeColorPreference extends ConsumerWidget {
  const ThemeColorPreference({super.key});

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
              Icon(Icons.palette_outlined, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(l10n.tr('profile.settings.theme_color'), style: AppTypography.bodyMedium)),
              Text(current.name, style: AppTypography.labelMedium.copyWith(color: colors.onSurfaceVariant))
            ],
          ),
          const SizedBox(height: AppSpacing.sm2),
          Wrap(
            spacing: AppSpacing.sm2,
            runSpacing: AppSpacing.sm2,
            children: [
              for (final preset in AppThemePreset.values)
                _ColorSwatch(
                  preset: preset,
                  selected: preset == current,
                  onTap: () => ref.read(themePresetControllerProvider.notifier).setPreset(preset),
                )
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.tr('profile.settings.theme_color.hint'), style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.preset, required this.selected, required this.onTap});

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
                border: Border.all(color: selected ? colors.onSurface : Colors.transparent, width: 2),
              ),
              alignment: Alignment.center,
              child: selected ? Icon(Icons.check, size: 14, color: colors.onPrimary) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class StartupTabPreference extends ConsumerWidget {
  const StartupTabPreference({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(startupTabControllerProvider);
    return DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: AppTypography.labelMedium,
        items: [for (final tab in appTabs) DropdownMenuItem(value: tab.pathSegment, child: Text(l10n.tr(tab.labelKey)))],
        onChanged: (value) {
          if (value != null) {
            ref.read(startupTabControllerProvider.notifier).setSegment(value);
          }
        });
  }
}

const _compactStyle = ButtonStyle(visualDensity: VisualDensity(horizontal: -3, vertical: -2), tapTargetSize: MaterialTapTargetSize.shrinkWrap);
