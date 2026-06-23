import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// 4 个 Metric 卡片(手机首页二级稿风格:可点击筛选时间窗)。
class HomeQuickNav extends StatelessWidget {
  const HomeQuickNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'New today',
            value: '128',
            delta: '+18.5%',
            icon: Icons.star_rounded,
            color: const Color(0xFFE3B341),
            onTap: () => context.go('/trending'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Metric(
            label: 'Star growth',
            value: '42.8K',
            delta: '+7.2%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF6E56CF),
            onTap: () => context.go('/trending'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Metric(
            label: 'Monitoring',
            value: '36',
            delta: '+3',
            icon: Icons.visibility_outlined,
            color: const Color(0xFF4CB5FF),
            onTap: () => context.go('/monitor'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Metric(
            label: 'Alerts today',
            value: '12',
            delta: '-2',
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFFE5A150),
            onTap: () => context.go('/monitor'),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                delta,
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF30A46C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
