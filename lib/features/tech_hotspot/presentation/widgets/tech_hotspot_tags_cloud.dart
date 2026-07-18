import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_view.dart';

class TechHotspotTagsCloud extends StatelessWidget {
  const TechHotspotTagsCloud({required this.tags, required this.onTagSelected, this.compact = false, super.key});

  final List<String> tags;
  final ValueChanged<String> onTagSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Text('#  ${l10n.tr('tech_hotspot.tag_cloud')}', style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant))
          else
            Row(
              children: [
                Icon(Icons.tag_rounded, size: 16, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.tr('tech_hotspot.tag_cloud'), style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700)),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            EmptyView(icon: Icons.sell_outlined, message: l10n.tr('tech_hotspot.empty.tags'))
          else
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final tag in tags) _Tag(label: tag, compact: compact, onSelected: () => onTagSelected(tag))])
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.compact, required this.onSelected});

  final String label;
  final bool compact;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(compact ? AppRadius.sm : AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            border: Border.all(color: compact ? colors.outlineVariant : Colors.transparent),
            borderRadius: BorderRadius.circular(compact ? AppRadius.sm : AppRadius.pill),
          ),
          child: Text('# $label', style: (compact ? AppTypography.bodySmall : AppTypography.labelMedium).copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
