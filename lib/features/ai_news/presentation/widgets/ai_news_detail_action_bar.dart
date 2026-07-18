import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/ai_news_feedback_providers.dart';
import '../../application/ai_news_library_providers.dart';
import '../../domain/ai_news_feedback.dart';
import '../../domain/ai_news_item.dart';

/*
*资讯详情底部固定操作栏。
*/
class AiNewsDetailActionBar extends ConsumerWidget {
  const AiNewsDetailActionBar({
    required this.item,
    required this.onShare,
    this.compact = true,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 分享操作。
  final VoidCallback onShare;

  // Desktop uses the same actions in a compact inline toolbar; mobile keeps
  // the fixed bottom bar so the primary reading actions remain reachable.
  final bool compact;

  @override
  /* 构建赞同、不感兴趣、收藏和分享四个操作。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final signal = ref.watch(aiNewsInterestProfileProvider).valueOrNull?.itemSignals[item.id];
    final saved = ref.watch(aiNewsItemStateProvider(item.id)).valueOrNull?.isReadLater ?? false;
    final toolbar = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: compact ? const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)) : BorderRadius.circular(AppRadius.lg),
        border: compact ? Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.52))) : Border.all(color: colors.outlineVariant.withValues(alpha: 0.72)),
        boxShadow: [
          if (compact)
            BoxShadow(
              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.07 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            children: [
              Expanded(
                child: _DetailActionItem(
                  icon: signal == AiNewsFeedbackSignal.more ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                  label: '${l10n.tr('ai_news.detail.like')} ${item.score}',
                  selected: signal == AiNewsFeedbackSignal.more,
                  onTap: () => _toggleFeedback(
                    context,
                    ref,
                    AiNewsFeedbackSignal.more,
                    signal,
                  ),
                ),
              ),
              Expanded(
                child: _DetailActionItem(
                  icon: signal == AiNewsFeedbackSignal.less ? Icons.sentiment_dissatisfied_rounded : Icons.sentiment_neutral_outlined,
                  label: l10n.tr('ai_news.detail.not_interested'),
                  selected: signal == AiNewsFeedbackSignal.less,
                  onTap: () => _toggleFeedback(
                    context,
                    ref,
                    AiNewsFeedbackSignal.less,
                    signal,
                  ),
                ),
              ),
              Expanded(
                child: _DetailActionItem(
                  icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  label: l10n.tr('ai_news.detail.bookmark'),
                  selected: saved,
                  onTap: () => _toggleReadLater(context, ref),
                ),
              ),
              Expanded(
                child: _DetailActionItem(
                  icon: Icons.ios_share_rounded,
                  label: l10n.tr('ai_news.detail.share'),
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (compact) {
      return SafeArea(top: false, child: toolbar);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.md),
      child: Align(alignment: Alignment.topCenter, child: toolbar),
    );
  }

  /* 切换当前资讯的兴趣信号。 */
  Future<void> _toggleFeedback(
    BuildContext context,
    WidgetRef ref,
    AiNewsFeedbackSignal next,
    AiNewsFeedbackSignal? current,
  ) async {
    final controller = ref.read(aiNewsFeedbackControllerProvider);
    if (current == next) {
      await controller.clear(item);
    } else {
      await controller.set(item, next);
    }
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tr('ai_news.feedback.saved'))));
  }

  /* 切换稍后读收藏状态。 */
  Future<void> _toggleReadLater(BuildContext context, WidgetRef ref) async {
    final added = await ref.read(aiNewsLibraryControllerProvider).toggleReadLater(item);
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.tr(
            added ? 'ai_news.read_later_added' : 'ai_news.read_later_removed',
          ),
        ),
      ),
    );
  }
}

/*
*底部操作栏中的单个图标与标签。
*/
class _DetailActionItem extends StatelessWidget {
  const _DetailActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  // 操作图标。
  final IconData icon;

  // 操作标签。
  final String label;

  // 是否为已选状态。
  final bool selected;

  // 点击操作。
  final VoidCallback onTap;

  @override
  /* 构建满足触控尺寸的底部操作。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
