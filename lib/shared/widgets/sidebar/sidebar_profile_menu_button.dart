import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class SidebarProfileMenuButton extends StatelessWidget {
  const SidebarProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: '更多',
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMenu(context),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      items: [
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              const Text('设置'),
            ],
          ),
          onTap: () => context.go('/profile'),
        ),
        PopupMenuItem<void>(
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              SizedBox(width: AppSpacing.md),
              Text('退出登录'),
            ],
          ),
          onTap: () {},
        ),
      ],
    );
  }
}
