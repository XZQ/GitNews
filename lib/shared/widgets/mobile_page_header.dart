import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/*
*移动端统一页头(参考主流资讯类 App 的顶部规范):
*- 单行:大号加粗标题居左 + 右侧纯图标动作,不放副标题文案
*- 可选:细胶囊搜索栏一行
*- 可选:底部插槽(分类 chips 等,由调用方保证单行横滑)
*自带 SafeArea 顶部避让与状态栏样式标注,页面不再需要 AppBar。
*/
class MobilePageHeader extends StatelessWidget {
  const MobilePageHeader({required this.title, this.actions = const [], this.search, this.bottom, super.key});

  final String title;

  // 右侧动作(IconButton / 徽章等),按传入顺序排列。
  final List<Widget> actions;

  // 细搜索栏(如 HeaderSearchField)。
  final Widget? search;

  // 标题/搜索下方的插槽(分类 chips 等)。
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final overlay = Theme.of(context).appBarTheme.systemOverlayStyle;
    final content = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm2,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          if (search != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: search!,
            ),
          if (bottom != null) ...[const SizedBox(height: AppSpacing.xs), bottom!],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
    if (overlay == null) {
      return content;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(value: overlay, child: content);
  }
}
