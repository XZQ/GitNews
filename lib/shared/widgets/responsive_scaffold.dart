import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/breakpoint.dart';
import 'app_sidebar.dart';
import 'window_title_bar.dart';

/// 三档响应式根 Scaffold。
///
/// - compact(< 600):底部 NavigationBar
/// - medium(600–1024):紧凑 NavigationRail(图标 + 选中标签) + 自绘标题栏
/// - expanded(≥ 1024):宽侧栏(品牌 + 大字号 + hover + 底部主题/登录) + 自绘标题栏
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
    final onTap = (int i) => navigationShell.goBranch(i,
        initialLocation: i == navigationShell.currentIndex);

    return switch (formFactor) {
      FormFactor.compact => Scaffold(
          body: navigationShell,
          bottomNavigationBar: _BottomBar(currentIndex: index, onTap: onTap),
        ),
      FormFactor.medium => Scaffold(
          body: Row(
            children: [
              _SideRail(currentIndex: index, onTap: onTap),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Column(
                  children: [
                    const WindowTitleBar(),
                    Expanded(child: navigationShell),
                  ],
                ),
              ),
            ],
          ),
        ),
      FormFactor.expanded => Scaffold(
          body: Row(
            children: [
              AppSidebar(currentIndex: index, onTap: onTap),
              Expanded(
                child: Column(
                  children: [
                    const WindowTitleBar(),
                    Expanded(child: navigationShell),
                  ],
                ),
              ),
            ],
          ),
        ),
    };
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
        for (final t in appTabs)
          NavigationDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon),
            label: t.label,
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
        for (final t in appTabs)
          NavigationRailDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon),
            label: Text(t.label),
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
