import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/breakpoint.dart';
import 'app_sidebar.dart';

/// 三档响应式根 Scaffold。
///
/// - compact(< 600):底部 NavigationBar
/// - medium(600–1024):紧凑 NavigationRail(图标 + 选中标签)
/// - expanded(≥ 1024):宽侧栏(品牌 + 大字号 + hover + 底部主题/登录)
///
/// 当停留在 **home** (`index == 0`) 时,expanded 不显示全局 [AppSidebar]
/// 而由 home 页面自身渲染带侧栏的 `DevIntelDesktopPage`。
class ResponsiveScaffold extends ConsumerWidget {
  const ResponsiveScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = navigationShell.currentIndex == 0
        ? '/home'
        : GoRouterState.of(context).matchedLocation;
    final index = appTabs.indexOfLocation(location);
    final formFactor = Breakpoints.of(context);
    void onTap(int i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        );

    return switch (formFactor) {
      FormFactor.compact => Scaffold(
          body: SafeArea(child: navigationShell),
          bottomNavigationBar: _BottomBar(currentIndex: index, onTap: onTap),
        ),
      FormFactor.medium => Scaffold(
          body: Row(
            children: [
              _SideRail(currentIndex: index, onTap: onTap),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: SafeArea(child: navigationShell)),
            ],
          ),
        ),
      FormFactor.expanded => Scaffold(
          body: Row(
            children: [
              AppSidebar(currentIndex: index, onTap: onTap),
              const _SidebarDragHandle(),
              Expanded(child: SafeArea(child: navigationShell)),
            ],
          ),
        ),
    };
  }
}

/// 侧栏拖拽手柄:用户拖动以改变侧栏宽度(200–800px)。
class _SidebarDragHandle extends ConsumerStatefulWidget {
  const _SidebarDragHandle();

  @override
  ConsumerState<_SidebarDragHandle> createState() => _SidebarDragHandleState();
}

class _SidebarDragHandleState extends ConsumerState<_SidebarDragHandle> {
  bool _hovered = false;
  bool _dragging = false;

  void _updateWidth(double delta) {
    final current = ref.read(sidebarWidthProvider);
    final next = (current + delta).clamp(kSidebarMinWidth, kSidebarMaxWidth);
    if (next != current) {
      ref.read(sidebarWidthProvider.notifier).state = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = _hovered || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => _updateWidth(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: 6,
          height: double.infinity,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 2,
              height: double.infinity,
              color: highlight
                  ? colors.primary.withValues(alpha: 0.6)
                  : colors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final spec in appTabs)
          NavigationDestination(
            icon: Icon(spec.icon),
            selectedIcon: Icon(spec.selectedIcon),
            label: spec.label,
          ),
      ],
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      extended: false,
      minExtendedWidth: 80,
      labelType: NavigationRailLabelType.selected,
      destinations: [
        for (final spec in appTabs)
          NavigationRailDestination(
            icon: Icon(spec.icon),
            selectedIcon: Icon(spec.selectedIcon),
            label: Text(spec.label),
          ),
      ],
    );
  }
}

/// 占位卡片(供各 Tab 占位页使用)。
class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    Chip(
                      label: const Text('响应式断点已生效'),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
