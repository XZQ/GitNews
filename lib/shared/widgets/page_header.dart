import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'header_search_field.dart';
import 'page_header_icon.dart';

/// 一级页通用顶部条。
///
/// 提供统一的高度 / padding / 可选图标块 / 标题副标题 / 可选搜索框 /
/// 可选 [HeaderStatPill] 集合 / 可选 trailing 动作,避免每个 feature 各自重画。
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconAccent = AppColors.brand,
    this.searchHint,
    this.searchValue = '',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.pills = const [],
    this.actions = const [],
    super.key,
  });

  final IconData? icon;
  final Color iconAccent;
  final String title;
  final String subtitle;
  final String? searchHint;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final List<Widget> pills;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasSearch = searchHint != null;
    final titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: colors.onSurface,
            height: 1.0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final titleSlot = hasSearch
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: titleContent,
          )
        : Expanded(child: titleContent);

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            PageHeaderIcon(icon: icon!, accent: iconAccent),
            const SizedBox(width: AppSpacing.md),
          ],
          titleSlot,
          if (hasSearch) ...[
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: HeaderSearchField(
                hintText: searchHint!,
                value: searchValue,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ],
          for (final pill in pills) ...[
            const SizedBox(width: AppSpacing.md),
            pill,
          ],
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        ],
      ),
    );
  }
}

/// Header 用的状态/统计胶囊:图标 + 文案 + 强调色。
class HeaderStatPill extends StatelessWidget {
  const HeaderStatPill({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs2,
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
