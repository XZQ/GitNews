import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/trending_data_source_mode_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/trending_providers.dart';

/* 
*趋势页顶部条:与其它一级页共享同一规格。
*/
class TrendingPageHeader extends ConsumerWidget {
  const TrendingPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sourceStatus = ref.watch(trendingDataSourceStatusProvider);
    final query = ref.watch(trendingSearchQueryProvider);
    return PageHeader(
      icon: Icons.trending_up_rounded,
      iconAccent: AppColors.info,
      title: l10n.tr('trending.title'),
      subtitle: l10n.tr('trending.page_header.subtitle'),
      searchHint: l10n.tr('trending.search_hint'),
      searchValue: query,
      onSearchChanged: (v) =>
          ref.read(trendingSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) {
        ref.read(trendingSearchQueryProvider.notifier).state = v;
        if (v.trim().isEmpty) return;
        context.go('/trending/repos');
      },
      pills: [
        const HeaderStatPill(
          icon: Icons.local_fire_department_rounded,
          label: '今日 +124',
          color: AppColors.success,
        ),
        HeaderStatPill(
          icon: sourceStatus.isGithub
              ? Icons.cloud_outlined
              : Icons.storage_rounded,
          label: sourceStatus.label(l10n),
          color: sourceStatus.mode == TrendingDataSourceMode.github
              ? AppColors.info
              : AppColors.brand,
        ),
      ],
      actions: [
        IconButton(
          tooltip: l10n.tr('common.refresh'),
          onPressed: () => refreshTrendingDigest(ref),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
