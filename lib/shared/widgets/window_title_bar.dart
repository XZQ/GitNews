import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/window_service.dart';
import '../../core/theme/app_spacing.dart';
import 'app_logo.dart';

final windowServiceProvider = Provider<WindowService>((ref) {
  return const WindowService();
});

/// 自定义窗口标题栏(替代 Windows 系统蓝色标题栏,实现沉浸式)。
///
/// - 顶部 32px 命中区由 native 端识别为 HTCAPTION,可拖动窗口
/// - 双击顶部最大/还原
/// - 右侧最小化/最大化/关闭按钮通过 MethodChannel 调用 native
class WindowTitleBar extends ConsumerStatefulWidget {
  const WindowTitleBar({super.key});

  @override
  ConsumerState<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends ConsumerState<WindowTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _refreshMaximized();
  }

  Future<void> _refreshMaximized() async {
    final value = await ref.read(windowServiceProvider).isMaximized();
    if (mounted) {
      setState(() => _isMaximized = value);
    }
  }

  Future<void> _onToggleMaximize() async {
    await ref.read(windowServiceProvider).toggleMaximize();
    await _refreshMaximized();
  }

  Future<void> _onMinimize() async {
    await ref.read(windowServiceProvider).minimize();
  }

  Future<void> _onClose() async {
    await ref.read(windowServiceProvider).close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Material(
      color: barColor,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            const LogoMark(size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'GitHub情报站',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.remove_rounded,
              onPressed: _onMinimize,
              tooltip: '最小化',
            ),
            _WindowButton(
              icon: _isMaximized
                  ? Icons.filter_drama_rounded
                  : Icons.crop_square_rounded,
              onPressed: _onToggleMaximize,
              tooltip: _isMaximized ? '还原' : '最大化',
            ),
            _WindowButton(
              icon: Icons.close_rounded,
              onPressed: _onClose,
              tooltip: '关闭',
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverColor = widget.isClose
        ? const Color(0xFFE81123)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final iconColor = widget.isClose && _hover
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 46,
            height: 32,
            color: _hover ? hoverColor : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 顶部 32px 之外的拖动热区占位,保持 hit-test 行为稳定。
class DragRegionSpacer extends StatelessWidget {
  const DragRegionSpacer({this.height = 32, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
