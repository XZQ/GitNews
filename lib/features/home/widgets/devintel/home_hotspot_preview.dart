import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../tech_hotspot/domain/tech_hotspot_models.dart';
import '../../../../shared/widgets/home_section_preview_card.dart';

/// 首页 AI 雷达 Top N 预览。
class HomeHotspotPreview extends ConsumerWidget {
  const HomeHotspotPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDigestProvider);
    final items = state.maybeWhen(
      data: (digest) => digest.topics.take(4).toList(),
      orElse: () => const <TechTopic>[],
    );
    return HomeSectionPreviewCard<TechTopic>(
      title: l10n.tr('home.section.hotspot.title'),
      subtitle: l10n.tr('home.section.hotspot.subtitle'),
      accentColor: AppColors.danger,
      icon: Icons.whatshot_rounded,
      path: '/tech_hotspot',
      items: items,
      tileBuilder: (context, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: _heatColor(item.heat),
        title: item.name,
        subtitle:
            '${item.category} · ${item.relatedRepos} ${l10n.tr('home.section.hotspot.meta_suffix')}',
        meta: '+${item.growth.toStringAsFixed(1)}%',
        onTap: () => context.go('/home/tech_hotspot_detail/${item.id}'),
      ),
    );
  }

  static Color _heatColor(int heat) {
    if (heat >= 90) return AppColors.danger;
    if (heat >= 75) return AppColors.warning;
    return AppColors.info;
  }
}
