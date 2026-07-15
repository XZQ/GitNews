import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/breakpoint.dart';
import 'app_sidebar.dart';

/* 
*三档响应式根 Scaffold。
*- compact(< 600):底部 NavigationBar
*- medium(600–1024):紧凑 NavigationRail(图标 + 选中标签)
*- expanded(≥ 1024):宽侧栏(品牌 + 大字号 + hover + 底部主题/登录)
*/
class ResponsiveScaffold extends ConsumerWidget {
  const ResponsiveScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = navigationShell.currentIndex == 0 ? '/home' : GoRouterState.of(context).matchedLocation;
    final index = appTabs.indexOfLocation(location);
    final formFactor = Breakpoints.of(context);
    void onTap(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

    return switch (formFactor) {
      FormFactor.compact => Scaffold(body: SafeArea(child: navigationShell), bottomNavigationBar: _BottomBar(currentBranchIndex: index, onTap: onTap)),
      FormFactor.medium => Scaffold(body: Row(children: [_SideRail(currentIndex: index, onTap: onTap), Expanded(child: SafeArea(child: navigationShell))])),
      FormFactor.expanded => Scaffold(body: Row(children: [AppSidebar(currentIndex: index, onTap: onTap), const _SidebarDragHandle(), Expanded(child: SafeArea(child: navigationShell))]))
    };
  }
}

/* 
*侧栏拖拽手柄:用户拖动以改变侧栏宽度(200–800px)。
*/
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
              width: highlight ? 2 : 1,
              height: double.infinity,
              color: highlight ? colors.primary.withValues(alpha: 0.6) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentBranchIndex, required this.onTap});

  final int currentBranchIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
        selectedIndex: mobileDestinationIndex(currentBranchIndex),
        onDestinationSelected: (index) {
          onTap(mobileAppTabs[index].branchIndex);
        },
        destinations: [
          for (final mobileSpec in mobileAppTabs)
            NavigationDestination(icon: Icon(appTabs[mobileSpec.branchIndex].icon), selectedIcon: Icon(appTabs[mobileSpec.branchIndex].selectedIcon), label: l10n.tr(mobileSpec.labelKey))
        ]);
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      extended: false,
      minExtendedWidth: 80,
      labelType: NavigationRailLabelType.selected,
      destinations: [for (final spec in appTabs) NavigationRailDestination(icon: Icon(spec.icon), selectedIcon: Icon(spec.selectedIcon), label: Text(l10n.tr(spec.labelKey)))],
    );
  }
}
