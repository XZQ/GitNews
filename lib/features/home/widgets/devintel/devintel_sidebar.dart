import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_logo.dart';

class DevIntelSidebar extends StatelessWidget {
  const DevIntelSidebar({super.key});

  static const Color _bg = Color(0xFF0F0F12);
  static const Color _hover = Color(0xFF23232B);

  static const List<_MenuSpec> _menu = <_MenuSpec>[
    _MenuSpec('总览', Icons.dashboard_rounded, '/home', true),
    _MenuSpec('趋势', Icons.show_chart_rounded, '/trending', false),
    _MenuSpec('报告', Icons.code_rounded, '/trending/repos', false),
    _MenuSpec(
        '开发者', Icons.people_alt_rounded, '/profile/developers', false),
    _MenuSpec(
        '设置', Icons.settings_rounded, '/profile/developer', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: _bg,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _BrandHeader(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              children: [
                for (var i = 0; i < _menu.length; i++)
                  _MenuItem(
                    spec: _menu[i],
                    onTap: () => context.go(_menu[i].route),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A2A30), height: 1),
          const _UserFooter(),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        LogoMark(size: 32),
        SizedBox(width: 10),
        Text(
          'DevIntel',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MenuSpec {
  const _MenuSpec(this.label, this.icon, this.route, this.selected);
  final String label;
  final IconData icon;
  final String route;
  final bool selected;
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.spec, required this.onTap});

  final _MenuSpec spec;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.spec.selected;
    final bg = selected
        ? AppColors.success.withValues(alpha: 0.14)
        : (_hovered ? DevIntelSidebar._hover : Colors.transparent);
    final fg = selected ? AppColors.success : AppColors.textSecondaryDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(widget.spec.icon, size: 18, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.spec.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? Colors.white : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF5840B5),
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Alex Chen',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Lead Architect',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
