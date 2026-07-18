import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/platform/window_service.dart';
import '../../core/theme/app_spacing.dart';
import 'app_logo.dart';

/*
*自定义窗口标题栏(替代 Windows 系统蓝色标题栏,实现沉浸式)。
*
*通过 [DesktopIntegrationService] 隐藏原生标题栏；左侧区域可拖动窗口，
*右侧保留最小化、最大化与关闭控制。
*/
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key});

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> {
  // Windows 窗口控制桥接，非桌面平台会安全降级。
  final WindowService _windowService = const WindowService();

  // 当前窗口是否最大化，用于切换图标与提示。
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _refreshMaximized();
  }

  Future<void> _refreshMaximized() async {
    final value = await _windowService.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = value);
    }
  }

  Future<void> _onToggleMaximize() async {
    await _windowService.toggleMaximize();
    await _refreshMaximized();
  }

  Future<void> _onMinimize() async {
    await _windowService.minimize();
  }

  Future<void> _onClose() async {
    await _windowService.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.md),
                      const LogoMark(size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.tr('app.name'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              _WindowButton(icon: Icons.remove_rounded, onPressed: _onMinimize, tooltip: l10n.tr('window.minimize')),
              _WindowButton(
                icon: _isMaximized ? Icons.filter_drama_rounded : Icons.crop_square_rounded,
                onPressed: _onToggleMaximize,
                tooltip: _isMaximized ? l10n.tr('window.restore') : l10n.tr('window.maximize'),
              ),
              _WindowButton(
                icon: Icons.close_rounded,
                onPressed: _onClose,
                tooltip: l10n.tr('window.close'),
                isClose: true,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/*
*Windows 应用框架:将自定义标题栏放在路由内容之外。
*
*移动端与 Web 不额外占用垂直空间，继续使用各自系统栏策略。
*/
class DesktopWindowFrame extends StatelessWidget {
  const DesktopWindowFrame({required this.child, super.key});

  // 路由或启动页内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isWindows) {
      return child;
    }
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (_) => Positioned.fill(
            child: Column(
              children: [
                const WindowTitleBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
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
    final hoverColor = widget.isClose ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final iconColor = widget.isClose && _hover ? theme.colorScheme.onError : theme.colorScheme.onSurface.withValues(alpha: 0.8);

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
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/* 
*顶部 32px 之外的拖动热区占位,保持 hit-test 行为稳定。
*/
class DragRegionSpacer extends StatelessWidget {
  const DragRegionSpacer({this.height = 32, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
