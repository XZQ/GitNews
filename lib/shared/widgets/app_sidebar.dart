import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_logo.dart';

/// 桌面侧栏宽度(用户可拖动,默认 240,范围 200–800)。
final sidebarWidthProvider = StateProvider<double>((ref) => 240);

const double kSidebarMinWidth = 200;
const double kSidebarMaxWidth = 800;

/// 桌面侧边栏:
/// - 顶部:品牌标识
/// - 中部:Tab 列表(整条 hover 高亮、selected 强调色)
/// - 底部:头像 + 设置 图标按钮
class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final width = ref.watch(sidebarWidthProvider);
    return Material(
      color: colors.surface,
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: colors.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            children: [
              const _SidebarHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  children: [
                    for (var i = 0; i < appTabs.length; i++)
                      _SidebarItem(
                        tab: appTabs[i],
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const _SidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          LogoMark(size: 32),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'GitHub 情报站',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    final isSelected = widget.selected;

    final bg = isSelected
        ? accent.withValues(alpha: 0.14)
        : (_hovered ? colors.surfaceContainerHighest : Colors.transparent);

    final fg = isSelected ? accent : colors.onSurfaceVariant;
    final fgStrong = isSelected ? accent : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? widget.tab.selectedIcon : widget.tab.icon,
                    size: 20,
                    color: fg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.tab.label,
                      style: AppTypography.titleSmall.copyWith(
                        color: fgStrong,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FooterIconButton(
            icon: Icons.account_circle_rounded,
            tooltip: '登录 / 我的',
            onTap: () => context.go('/profile'),
            avatar: true,
          ),
          _FooterIconButton(
            icon: Icons.settings_outlined,
            tooltip: '设置',
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _FooterIconButton extends StatefulWidget {
  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.avatar = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool avatar;

  @override
  State<_FooterIconButton> createState() => _FooterIconButtonState();
}

class _FooterIconButtonState extends State<_FooterIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg =
        _hovered ? colors.primary.withValues(alpha: 0.16) : Colors.transparent;
    final fg = _hovered ? colors.primary : colors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.avatar ? 40 : 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.avatar
                    ? (_hovered
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest)
                    : bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                gradient: widget.avatar && !_hovered
                    ? LinearGradient(
                        colors: [colors.primaryContainer, colors.primary],
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: widget.avatar ? 22 : 20,
                color: widget.avatar && !_hovered ? colors.onPrimary : fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
