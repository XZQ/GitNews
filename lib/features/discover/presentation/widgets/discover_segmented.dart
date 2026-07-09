import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 发现页分段选择器:仓库 / Skills / 官方组织 / 知名人士。
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
    _Seg('people', 'discover.tab.people', Icons.person_search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in _items)
                ChoiceChip(
                  selected: value == item.value,
                  showCheckmark: false,
                  avatar: Icon(item.icon, size: 16),
                  label: Text(l10n.tr(item.labelKey)),
                  onSelected: (_) {
                    if (value != item.value) {
                      onChanged(item.value);
                    }
                  },
                ),
            ],
          ),
        ),
      );
    }
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
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
                },
              ),
            ],
          ],
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs2,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(
              color: selected ? colors.primary.withValues(alpha: 0.42) : colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs2),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
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
