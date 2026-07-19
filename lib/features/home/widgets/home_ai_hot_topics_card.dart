import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/data_freshness.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../ai_news/application/ai_news_providers.dart';
import '../../ai_news/domain/ai_hot_topic.dart';

/*
*总览顶部的 AI HOT 当前热点卡。
*它优先呈现跨来源讨论强度,加载失败时不阻断总览中的其他情报区块。
*/
class HomeAiHotTopicsCard extends ConsumerWidget {
  const HomeAiHotTopicsCard({this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg), super.key});

  // 适配总览三档布局的外边距。
  final EdgeInsetsGeometry padding;

  @override
  /* 构建当前热点的独立加载、错误与数据状态。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiHotTopicsProvider);
    return Padding(
      padding: padding,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: state.when(
          loading: () => _Message(
            icon: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            text: l10n.tr('ai_news.hot_topics.loading'),
          ),
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

/*
*当前热点的标题与前三条信号。
*/
class _Topics extends StatelessWidget {
  const _Topics({required this.items, required this.freshness});

  // 服务端按多源热度排序的热点。
  final List<AiHotTopic> items;

  // 热点响应新鲜度。
  final DataFreshness freshness;

  @override
  /* 构建热点标题与内容列表。 */
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

/*
*总览热点列表中的单条可点击信号。
*/
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});

  // 当前热点。
  final AiHotTopic topic;

  @override
  /* 构建热点标题、来源数和信号数。 */
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
                  Text(
                    topic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(color: colors.onSurface, height: 1.4),
                  ),
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

  /* 在总览分支中打开共用 WebView 的精简标题栏变体。 */
  static void _open(BuildContext context, AiHotTopic topic) {
    context.pushNamed('home_hot_topic_webview', queryParameters: {'url': topic.permalink, 'title': topic.title});
  }
}

/*
*当前热点的紧凑加载或错误提示。
*/
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
        Expanded(
          child: Text(text, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        if (action != null) action!,
      ],
    );
  }
}
