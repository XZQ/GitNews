import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/*
*区块标题:左侧标题 + 副标题,右侧元信息/操作(均可空)。
*
*[meta] 是移动端设计稿的右对齐弱化说明(如「今日 · 3 个项目」「Top 8」),
*  与堆在标题下方的 [subtitle] 是两种排布,按版面二选一。同时传入时
*  meta 在右、subtitle 在下,不冲突。
*/
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    super.key,
  });

  // meta 的宽度上限:约为 390 逻辑像素窄屏的 40%,超出则省略。
  // 用固定上限而不是 Flexible,是因为 Flexible 与左侧 Expanded 会平分剩余
  // 空间,导致短 meta 也占掉半行、标题被提前截断。
  static const double _maxMetaWidth = 160;

  final String title;
  final String? subtitle;

  // 右对齐的弱化元信息;走等宽字体,承载口径/计数说明。
  final String? meta;

  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[const SizedBox(height: AppSpacing.xxs), Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant))]
                ],
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxMetaWidth),
                child: Text(
                  meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
            if (trailing != null) trailing!,
            if (onTap != null && showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: AppTypography.titleMedium.fontSize!,
                color: colors.onSurfaceVariant,
              )
            ]
          ],
        ),
      ),
    );
  }
}
