import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'sidebar_profile_menu_button.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: SidebarProfileCard(),
    );
  }
}

class SidebarProfileCard extends StatefulWidget {
  const SidebarProfileCard({super.key});

  @override
  State<SidebarProfileCard> createState() => _SidebarProfileCardState();
}

class _SidebarProfileCardState extends State<SidebarProfileCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  const SidebarProfileAvatar(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'XZQ',
                          style: AppTypography.titleSmall.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm - 2,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.starGold.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Text(
                                'PRO',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm - 2),
                            const Flexible(
                              child: Text(
                                '在线',
                                style: AppTypography.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const SidebarProfileMenuButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarProfileAvatar extends StatelessWidget {
  const SidebarProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.primary],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: colors.onPrimary,
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: colors.surface, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
