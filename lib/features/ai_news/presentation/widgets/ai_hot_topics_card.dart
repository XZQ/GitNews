import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/data_freshness.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../application/ai_news_providers.dart';
import '../../domain/ai_hot_topic.dart';

/*
*AI HOT 当前热点卡。
*它表达多信源讨论强度,不合并到 GitHub AI 雷达;加载失败也不阻断资讯列表。
*/
class AiHotTopicsCard extends ConsumerWidget {
  const AiHotTopicsCard({super.key});

  @override
  /* 构建当前热点独立状态。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiHotTopicsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xl, 0),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: state.when(
          loading: () => _Message(icon: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)), text: l10n.tr('ai_news.hot_topics.loading')),
          error: (_, __) => _Message(
            icon: Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.error),
            text: l10n.tr('ai_news.hot_topics.failed'),
            action: TextButton(onPressed: () => ref.invalidate(aiHotTopicsProvider), child: Text(l10n.tr('common.retry'))),
          ),
          data: (result) => _Topics(items: result.data, freshness: result.freshness),
        ),
      ),
    );
  }
}

class _Topics extends StatelessWidget {
  const _Topics({required this.items, required this.freshness});

  // 服务端按多源热度排序的热点。
  final List<AiHotTopic> items;

  // 热点响应新鲜度。
  final DataFreshness freshness;

  @override
  /* 构建标题与最多三条热点。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tr('ai_news.hot_topics.title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
                  Text(l10n.tr('ai_news.hot_topics.subtitle'), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            DataFreshnessBadge(freshness: freshness),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Text(l10n.tr('ai_news.hot_topics.empty'), style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant))
        else
          for (final topic in items.take(3)) _TopicRow(topic: topic),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});

  // 当前热点。
  final AiHotTopic topic;

  @override
  /* 构建可打开 AI HOT canonical 的热点行。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _open(context, topic),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.titleSmall.copyWith(color: colors.onSurface, height: 1.4)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${l10n.tr('ai_news.hot_topics.sources').replaceAll('{count}', '${topic.sourceCount}')} · ${l10n.tr('ai_news.hot_topics.signals').replaceAll('{count}', '${topic.signalCount}')}',
                    style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, AiHotTopic topic) {
    final location = Uri(
      path: '/ai_news/webview',
      queryParameters: {'url': topic.permalink, 'title': topic.title},
    );
    context.go(location.toString());
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  // 状态图标。
  final Widget icon;

  // 状态文案。
  final String text;

  // 可选重试操作。
  final Widget? action;

  @override
  /* 构建紧凑状态行。 */
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        if (action != null) action!,
      ],
    );
  }
}
