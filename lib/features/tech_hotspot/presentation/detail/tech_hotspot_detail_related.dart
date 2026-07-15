import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/tech_hotspot_models.dart';
import 'tech_hotspot_detail_topic_header.dart' show techHeatColor;

class TechHotspotDetailRelated extends StatelessWidget {
  const TechHotspotDetailRelated({required this.items, super.key});

  final List<TechTopic> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(title: l10n.tr('tech_hotspot.detail.related'), subtitle: l10n.tr('tech_hotspot.detail.related.subtitle')),
          ),
          for (final e in items) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              onTap: () => context.push('/tech_hotspot/detail/${e.id}'),
              leading: Icon(Icons.whatshot_rounded, size: 20, color: techHeatColor(e.heat)),
              title: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall,
              ),
              subtitle: Text('${e.category} · ${l10n.tr('tech_hotspot.detail.related_suffix').replaceAll('{heat}', e.heat.toString())}', style: AppTypography.labelSmall),
              trailing: Text('+${e.growth.toStringAsFixed(1)}%', style: AppTypography.labelSmall.copyWith(color: AppColors.trendUp, fontWeight: FontWeight.w600)),
            )
          ]
        ],
      ),
    );
  }
}
