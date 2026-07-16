import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/ai_news_library_providers.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_article_card.dart';

/*
*单条资讯行:带背景的条目卡片 + 卡片间距。
*旧版的「左列时间 + 圆点 + 竖线」时间线槽已移除——它占约 15% 行宽,
*且与 meta 行的相对时间重复;日期分组仍由 [AiNewsDayHeader] 承担。
*保持原 API(item/onTap/eventSources)不变,调用方零改动。
*/
class AiNewsTimelineRow extends ConsumerWidget {
  const AiNewsTimelineRow({
    required this.item,
    required this.onTap,
    this.eventSources = const [],
    super.key,
  });

  final AiNewsItem item;
  final VoidCallback onTap;
  final List<String> eventSources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(aiNewsItemStateProvider(item.id)).valueOrNull?.isReadLater ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AiNewsArticleCard(
        item: item,
        onTap: onTap,
        eventSources: eventSources,
        isBookmarked: isBookmarked,
        onBookmarkTap: () => _toggleBookmark(context, ref),
      ),
    );
  }

  /* 切换稍后读并反馈结果。 */
  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    final added = await ref.read(aiNewsLibraryControllerProvider).toggleReadLater(item);
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tr(added ? 'ai_news.read_later_added' : 'ai_news.read_later_removed'))));
  }
}
