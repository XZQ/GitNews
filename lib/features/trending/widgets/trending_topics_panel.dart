import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/trending_repository.dart';

/* 
*话题趋势面板:展示本周高频技术话题的词云。
*/
class TrendingTopicsPanel extends StatelessWidget {
  const TrendingTopicsPanel({this.topics = const [], this.onTap, super.key});

  // GitHub Search 结果中聚合的真实 repository topics。
  final List<TrendingTopicEntity> topics;

  // 可选的完整热榜页入口。
  final VoidCallback? onTap;

  /* 构建真实 topic 词云；无远端数据时保留本地种子兜底。 */
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('trending.topics.title'),
            subtitle: l10n.tr('trending.topics.subtitle'),
            trailing: topics.isEmpty ? null : MetricBasisBadge(basis: topics.first.basis),
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.md),
          _TopicWordCloud(l10n: l10n, topics: topics),
        ],
      ),
    );
  }
}

/*
* 根据真实 topic 统计或本地种子构建词云。
*/
class _TopicWordCloud extends StatelessWidget {
  const _TopicWordCloud({required this.l10n, required this.topics});

  // 本地化文本，用于离线种子兜底。
  final AppLocalizations l10n;

  // GitHub Search 聚合的 topic 统计。
  final List<TrendingTopicEntity> topics;

  /* 按仓库覆盖数和 Star 总量计算 topic 的视觉权重。 */
  @override
  Widget build(BuildContext context) {
    if (topics.isNotEmpty) {
      final visible = topics.take(8).toList(growable: false);
      final rawMaxScore = visible.map(_score).reduce((left, right) => left > right ? left : right);
      final maxScore = rawMaxScore <= 0 ? 1.0 : rawMaxScore;
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final topic in visible)
            _TopicWord(
              text: topic.name,
              size: 13 + 9 * (_score(topic) / maxScore),
              weight: 0.4 + 0.5 * (_score(topic) / maxScore),
            ),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _TopicWord(text: l10n.tr('home.topic.agents'), size: 22, weight: 0.9),
        _TopicWord(text: l10n.tr('home.topic.devtools'), size: 20, weight: 0.85),
        _TopicWord(text: l10n.tr('home.topic.rag'), size: 16, weight: 0.6),
        _TopicWord(text: l10n.tr('home.topic.llm'), size: 18, weight: 0.7),
        const _TopicWord(text: 'Web3', size: 17, weight: 0.65),
        _TopicWord(text: l10n.tr('home.topic.cloud_native'), size: 14, weight: 0.5),
        _TopicWord(text: l10n.tr('home.topic.data_infra'), size: 13, weight: 0.45),
        _TopicWord(text: l10n.tr('home.topic.security'), size: 15, weight: 0.55)
      ],
    );
  }

  /* 组合仓库覆盖数与 Star 总量，避免单个超大仓库完全主导词云。 */
  double _score(TrendingTopicEntity topic) {
    return topic.repoCount * 1000 + topic.starCount.clamp(0, 1000000) / 1000;
  }
}

/*
* 话题词云中的单个文字节点。
*/
class _TopicWord extends StatelessWidget {
  const _TopicWord({required this.text, required this.size, required this.weight});

  final String text;
  final double size;
  final double weight;

  /* 根据话题权重构建字号和主色深浅。 */
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lightness = 0.45 + weight * 0.4;
    return Text(text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: HSLColor.fromColor(colors.primary).withLightness(lightness.clamp(0.3, 0.7)).toColor(),
        ));
  }
}
