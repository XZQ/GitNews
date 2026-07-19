import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'sidebar/sidebar_footer.dart';
import 'sidebar/sidebar_header.dart';
import 'sidebar/sidebar_item.dart';

// 桌面侧栏宽度(用户可拖动,默认 240,范围 200–800)。
final sidebarWidthProvider = StateProvider<double>((ref) => 240);

const double kSidebarMinWidth = 200;
// Keep the navigation rail readable while preserving enough room for the
// main workspace on ordinary desktop windows.
const double kSidebarMaxWidth = 360;

/* 
*桌面侧边栏:
*- 顶部:品牌标识
*- 中部:Tab 列表(整条 hover 高亮、selected 强调色)
*- 底部:头像 + 设置 图标按钮
*/
class AppSidebar extends ConsumerWidget {
  const AppSidebar({required this.currentIndex, required this.onTap, super.key});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final width = ref.watch(sidebarWidthProvider);
    return FocusTraversalGroup(
      child: Material(
        color: colors.surface,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              const SidebarHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  children: [for (var i = 0; i < appTabs.length; i++) SidebarItem(tab: appTabs[i], selected: i == currentIndex, onTap: () => onTap(i))],
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: colors.outlineVariant.withValues(alpha: 0.35)),
              const SidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
