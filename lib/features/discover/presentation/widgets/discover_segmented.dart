import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/*
 *发现页分段选择器:仓库 / Skills / 官方组织 / 知名人士。
 */
class DiscoverSegmented extends StatelessWidget {
  const DiscoverSegmented({
    required this.value,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool compact;

  static const List<_Seg> _items = [
    _Seg('repos', 'discover.tab.repos', Icons.local_fire_department_rounded),
    _Seg('skills', 'discover.tab.skills', Icons.extension_rounded),
    _Seg('official', 'discover.tab.official', Icons.verified_rounded),
    _Seg('people', 'discover.tab.people', Icons.person_search_rounded)
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (compact) {
      // 移动端按设计稿固定三类入口;「官方内容」汇总官方账号与知名人士。
      final compactItems = _items.take(3).toList(growable: false);
      return SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Row(
            children: [
              for (var i = 0; i < compactItems.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: i == 2 ? 3 : 4,
                  child: _CompactSegmentChip(
                    selected: value == compactItems[i].value || (compactItems[i].value == 'official' && value == 'people'),
                    label: l10n.tr(compactItems[i].labelKey),
                    onTap: () {
                      if (value != compactItems[i].value) {
                        onChanged(compactItems[i].value);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
        height: 52,
        decoration: BoxDecoration(color: colors.surface, border: Border(bottom: BorderSide(color: colors.outlineVariant))),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _SegmentChip(
                    icon: _items[i].icon,
                    label: l10n.tr(_items[i].labelKey),
                    selected: value == _items[i].value,
                    onTap: () {
                      if (value != _items[i].value) {
                        onChanged(_items[i].value);
                      }
                    })
              ]
            ])));
  }
}

/*
*移动端发现分类入口 — 实心选中态分段按钮。
*
*设计稿在窄屏上用「选中填充主色 + 未选中描边」表达当前分类,比浅色底
*  更容易在一屏三个入口里一眼定位;同时去掉图标,让中文标签有足够
*  横向空间不被截断。
*/
class _CompactSegmentChip extends StatelessWidget {
  const _CompactSegmentChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    final radius = BorderRadius.circular(AppRadius.sm);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
            borderRadius: radius,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: AppTypography.labelMedium.copyWith(color: foreground, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = selected ? colors.primary : colors.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs2),
          decoration: BoxDecoration(
            color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(color: selected ? colors.primary.withValues(alpha: 0.42) : colors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs2),
              Text(label, style: AppTypography.labelMedium.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w600))
            ],
          ),
        ),
      ),
    );
  }
}

class _Seg {
  const _Seg(this.value, this.labelKey, this.icon);

  final String value;
  final String labelKey;
  final IconData icon;
}
