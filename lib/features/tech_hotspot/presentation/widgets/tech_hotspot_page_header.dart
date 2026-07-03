import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';

/// 技术趋势页顶部条。
class TechHotspotPageHeader extends StatelessWidget {
  const TechHotspotPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      icon: Icons.whatshot_rounded,
      iconAccent: AppColors.warning,
      title: l10n.tr('tech_hotspot.title'),
      subtitle: l10n.tr('tech_hotspot.subtitle'),
      searchHint: l10n.tr('tech_hotspot.search_hint'),
      onSearchSubmitted: (v) {
        if (v.trim().isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('tech_hotspot.search.noti'))),
        );
      },
      pills: [
        HeaderStatPill(
          icon: Icons.local_fire_department_rounded,
          label: l10n.tr('tech_hotspot.pill.growth'),
          color: AppColors.danger,
        ),
        HeaderStatPill(
          icon: Icons.tag_rounded,
          label: l10n
              .tr('tech_hotspot.pill.themes')
              .replaceAll('{n}', '8'),
          color: AppColors.brand,
        ),
      ],
      actions: [
        IconButton(
          tooltip: l10n.tr('tech_hotspot.filter'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.tr('tech_hotspot.filter.noti'))),
            );
          },
          icon: const Icon(Icons.tune_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
