import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../application/ai_news_library_providers.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_article_card.dart';

/*
*单条资讯行。
*
*移动端:条目本身不带外框,由本组件提供卡片表面 + 底部发丝分隔线,使同一
*  天的连续条目拼成一张列表卡;[isLastInGroup] 为真时省略分隔线并补上
*  底部圆角,让分组末尾收口。
*桌面端:维持原先「一条一卡 + 卡间距」的高密度排版。
*保持原 API(item/onTap/eventSources)不变,调用方零改动。
*/
class AiNewsTimelineRow extends ConsumerWidget {
  const AiNewsTimelineRow({required this.item, required this.onTap, this.eventSources = const [], this.isFirstInGroup = false, this.isLastInGroup = false, super.key});

  final AiNewsItem item;
  final VoidCallback onTap;
  final List<String> eventSources;

  // 是否为当天分组的首条,决定顶部圆角。
  final bool isFirstInGroup;

  // 是否为当天分组的末条,决定底部圆角与是否画分隔线。
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(aiNewsItemStateProvider(item.id)).value?.isReadLater ?? false;
    final card = AiNewsArticleCard(item: item, onTap: onTap, eventSources: eventSources, isBookmarked: isBookmarked, onBookmarkTap: () => _toggleBookmark(context, ref));
    if (!Breakpoints.isCompact(context)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: card,
      );
    }
    final colors = Theme.of(context).colorScheme;
    const radius = Radius.circular(AppRadius.card);
    final line = BorderSide(color: colors.outlineVariant.withValues(alpha: 0.54));
    // 只有首行画上边框,其余行靠上一行的下边框断行。若每行都画完整外框,
    // 相邻两条 1px 边线会叠成 2px 的粗线。
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: line, right: line, bottom: line, top: isFirstInGroup ? line : BorderSide.none),
        borderRadius: BorderRadius.vertical(top: isFirstInGroup ? radius : Radius.zero, bottom: isLastInGroup ? radius : Radius.zero),
      ),
      margin: EdgeInsets.only(bottom: isLastInGroup ? AppSpacing.md : 0),
      child: card,
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
