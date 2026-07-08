import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/tech_hotspot_providers.dart';
import '../../domain/tech_hotspot_models.dart';

/* 
*AI 雷达页顶部条。
*/
class TechHotspotPageHeader extends ConsumerWidget {
  const TechHotspotPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final digest = ref.watch(filteredTechHotspotDigestProvider).valueOrNull;
    final query = ref.watch(techHotspotSearchQueryProvider);
    final category = ref.watch(techHotspotCategoryFilterProvider);
    final topicCount = digest?.topics.length ?? 8;
    return PageHeader(
      icon: Icons.device_hub_rounded,
      iconAccent: AppColors.brand,
      title: l10n.tr('tech_hotspot.title'),
      subtitle: l10n.tr('tech_hotspot.subtitle'),
      searchHint: l10n.tr('tech_hotspot.search_hint'),
      searchValue: query,
      onSearchChanged: (v) =>
          ref.read(techHotspotSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) =>
          ref.read(techHotspotSearchQueryProvider.notifier).state = v,
      onRefresh: () => ref.invalidate(techHotspotDigestProvider),
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
              .replaceAll('{n}', '$topicCount'),
          color: AppColors.brand,
        ),
      ],
      actions: [
        HeaderAction(
          icon: category == 'all'
              ? Icons.tune_rounded
              : Icons.filter_alt_rounded,
          tooltip: l10n.tr('tech_hotspot.filter'),
          onPressed: () => _showCategoryFilterSheet(context, ref),
        ),
      ],
    );
  }
}

Future<void> _showCategoryFilterSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final categories = _categoryOptions(
    ref.read(techHotspotDigestProvider).valueOrNull,
  );
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Consumer(
            builder: (context, sheetRef, _) {
              final selected =
                  sheetRef.watch(techHotspotCategoryFilterProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('筛选分类', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in categories)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: selected == option.value,
                          onSelected: (_) {
                            sheetRef
                                .read(
                                  techHotspotCategoryFilterProvider.notifier,
                                )
                                .state = option.value;
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

List<_CategoryOption> _categoryOptions(TechHotspotDigest? digest) {
  final values = <String>{'all'};
  if (digest != null) {
    for (final topic in digest.topics) {
      values.add(topic.category);
    }
  } else {
    values.addAll(const ['AI', 'Agent', 'DevTools', 'Data', 'Infra']);
  }

  return [
    for (final value in values)
      _CategoryOption(value: value, label: value == 'all' ? '全部' : value),
  ];
}

class _CategoryOption {
  const _CategoryOption({required this.value, required this.label});

  final String value;
  final String label;
}
