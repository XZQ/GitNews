import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/header_search_field.dart';
import '../../../../shared/widgets/page_header_icon.dart';
import '../../application/ai_news_providers.dart';

/// AI 动态页顶部条:标题 + 副标题 + 搜索 + 通知。
class AiNewsPageHeader extends ConsumerWidget {
  const AiNewsPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: Icons.auto_awesome_rounded,
            accent: AppColors.brand,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI 动态',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '每日 5 分钟读完 AI 世界',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          const Expanded(
            child: HeaderSearchField(hintText: '搜索资讯、模型、公司...'),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            tooltip: '刷新',
            onPressed: () => ref.invalidate(aiNewsDigestProvider),
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: AppColors.brandDark,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '10 条新更',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700,
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
