import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/* 
*话题趋势面板:展示本周高频技术话题的词云。
*/
class TrendingTopicsPanel extends StatelessWidget {
  const TrendingTopicsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SectionHeader(title: l10n.tr('trending.topics.title'), subtitle: l10n.tr('trending.topics.subtitle')), const SizedBox(height: AppSpacing.md), _TopicWordCloud(l10n: l10n)],
      ),
    );
  }
}

class _TopicWordCloud extends StatelessWidget {
  const _TopicWordCloud({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
}

class _TopicWord extends StatelessWidget {
  const _TopicWord({required this.text, required this.size, required this.weight});

  final String text;
  final double size;
  final double weight;

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
