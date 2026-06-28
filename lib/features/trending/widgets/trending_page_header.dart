import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/header_search_field.dart';
import '../../../shared/widgets/page_header_icon.dart';

/// 趋势页顶部条:与 [AiNewsPageHeader] / [TechHotspotPageHeader] 共享同一规格。
class TrendingPageHeader extends StatelessWidget {
  const TrendingPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          const PageHeaderIcon(
            icon: Icons.trending_up_rounded,
            accent: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GitHub热榜',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Star 增速榜 · 仓库发现',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: HeaderSearchField(
              hintText: '搜索仓库、语言、主题...',
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                context.go('/trending/repos');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const _StatPill(
            icon: Icons.local_fire_department_rounded,
            label: '今日 +124',
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            tooltip: '刷新',
            onPressed: () {},
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
