import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DevIntelTopHeader extends StatelessWidget {
  const DevIntelTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '开发者情报',
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.onSurface,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '实时生态洞察',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const _SearchField(),
            const SizedBox(width: AppSpacing.md),
            const _BellWithDot(),
            const SizedBox(width: AppSpacing.md),
            const _LiveSyncBadge(),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 320,
      height: 44,
      child: TextField(
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          context.go('/trending/repos');
        },
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          hintText: '搜索仓库、标签...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () => context.go('/monitor'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      tooltip: '监控中心',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }
}

class _LiveSyncBadge extends StatelessWidget {
  const _LiveSyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LivePulseDot(),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            '实时同步',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.success.withValues(alpha: 0.4),
              AppColors.success,
              t,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.5 * t),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
