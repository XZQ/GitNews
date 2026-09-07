import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/home_section_preview_card.dart';
import '../../../../shared/widgets/repo_star_change.dart';
import '../../../trending/application/trending_providers.dart';

/* 
*首页 GitHub热榜 Top N 预览。
*/
class HomeTrendingPreview extends ConsumerWidget {
  const HomeTrendingPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(trendingDigestProvider).value?.trendingRepos.take(4).toList() ?? const <RepoEntity>[];
    return HomeSectionPreviewCard<RepoEntity>(
      title: l10n.tr('home.section.trending.title'),
      subtitle: l10n.tr('home.section.trending.subtitle'),
      accentColor: AppColors.warning,
      icon: Icons.local_fire_department_rounded,
      path: '/trending',
      items: items,
      tileBuilder: (_, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: Color(item.accentArgb),
        title: item.fullName,
        subtitle: item.description,
        meta: repoStarChangeText(item),
        onTap: () => context.go('/home/detail/${Uri.encodeComponent(item.fullName)}'),
      ),
    );
  }
}
