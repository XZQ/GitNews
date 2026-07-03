import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/ai_news_providers.dart';

/// AI 动态页顶部条 — 复用 [PageHeader] 体系。
class AiNewsPageHeader extends ConsumerWidget {
  const AiNewsPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      title: l10n.tr('ai_news.title'),
      subtitle: l10n.tr('ai_news.subtitle'),
      searchHint: l10n.tr('ai_news.search_hint'),
      onSearchSubmitted: (v) {
        // TODO(ai_news): 接入搜索筛选
      },
      pills: [
        HeaderStatPill(
          icon: Icons.bolt_rounded,
          label: l10n.tr('ai_news.realtime_pill'),
          color: AppColors.brand,
        ),
      ],
      actions: [
        IconButton(
          tooltip: l10n.tr('common.refresh'),
          onPressed: () => ref.invalidate(aiNewsItemsNotifierProvider),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
