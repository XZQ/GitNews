import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SidebarItem extends StatefulWidget {
  const SidebarItem({required this.tab, required this.selected, required this.onTap, super.key});

  final TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final accent = colors.primary;
    final isSelected = widget.selected;

    // 工具风基线:选中态用中性底 + 文字对比表达,主色只留给左侧 3px
    // 指示条;导航不再整体染色,视线焦点让给内容区。
    final bg = isSelected ? colors.surfaceContainerHighest : (_hovered ? colors.surfaceContainerHighest.withValues(alpha: 0.6) : Colors.transparent);

    final fg = isSelected ? colors.onSurface : colors.onSurfaceVariant;
    final fgStrong = colors.onSurface;
    final label = l10n.tr(widget.tab.labelKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Semantics(
          label: label,
          button: true,
          selected: isSelected,
          onTap: widget.onTap,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm2),
                      child: Row(
                        children: [
                          Icon(isSelected ? widget.tab.selectedIcon : widget.tab.icon, size: 20, color: fg),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              label,
                              style: AppTypography.titleSmall.copyWith(color: fgStrong, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        left: 4,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(AppRadius.dot)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
