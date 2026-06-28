import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '偏好设置',
            subtitle: '主题 / 通知 / 启动',
          ),
          const SizedBox(height: AppSpacing.md),
          const _ThemeColorRow(),
          const SizedBox(height: AppSpacing.sm),
          const ProfileSettingRow(
            icon: Icons.dark_mode_outlined,
            label: '深色模式',
            trailing: _ThemeToggle(),
          ),
          const ProfileSettingRow(
            icon: Icons.notifications_none,
            label: '通知权限',
            trailing: Text('已启用', style: AppTypography.labelMedium),
          ),
          const ProfileSettingRow(
            icon: Icons.rocket_launch_outlined,
            label: '启动主题',
            trailing: Text('首页', style: AppTypography.labelMedium),
          ),
          const ProfileSettingRow(
            icon: Icons.cloud_outlined,
            label: '数据源',
            trailing: Text('GitHub', style: AppTypography.labelMedium),
          ),
          ProfileSettingRow(
            icon: Icons.code,
            label: '开发者选项',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developer'),
          ),
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

/// 主题色选择行:展示色圆,点击切换 seed。
class _ThemeColorRow extends ConsumerWidget {
  const _ThemeColorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const Expanded(
                child: Text('主题色', style: AppTypography.bodyMedium),
              ),
              Text(
                current.name,
                style: AppTypography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Wrap(
            spacing: AppSpacing.sm + 2,
            runSpacing: AppSpacing.sm + 2,
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
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            '切换整 App 强调色(默认灰白)',
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
        borderRadius: BorderRadius.circular(AppSpacing.xxxl),
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
