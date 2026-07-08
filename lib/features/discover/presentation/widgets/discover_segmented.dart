import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

/// 发现页分段选择器:流行仓库 Top20 / Agent Skills 榜。
class DiscoverSegmented extends StatelessWidget {
  const DiscoverSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const List<_Seg> _items = [
    _Seg('repos', 'discover.tab.repos', Icons.local_fire_department_rounded),
    _Seg('skills', 'discover.tab.skills', Icons.extension_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
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
              if (value != item.value) onChanged(item.value);
            },
          ),
      ],
    );
  }
}

class _Seg {
  const _Seg(this.value, this.labelKey, this.icon);

  final String value;
  final String labelKey;
  final IconData icon;
}
