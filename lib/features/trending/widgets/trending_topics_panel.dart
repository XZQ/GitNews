import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/// 话题趋势面板:展示本周高频技术话题的词云。
class TrendingTopicsPanel extends StatelessWidget {
  const TrendingTopicsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '话题趋势',
            subtitle: '本周高频出现的技术话题',
          ),
          SizedBox(height: AppSpacing.md),
          _TopicWordCloud(),
        ],
      ),
    );
  }
}

class _TopicWordCloud extends StatelessWidget {
  const _TopicWordCloud();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _TopicWord(text: 'AI 智能体', size: 22, weight: 0.9),
        _TopicWord(text: '开发工具', size: 20, weight: 0.85),
        _TopicWord(text: '检索增强生成', size: 16, weight: 0.6),
        _TopicWord(text: '大语言模型', size: 18, weight: 0.7),
        _TopicWord(text: 'Web3', size: 17, weight: 0.65),
        _TopicWord(text: '云原生', size: 14, weight: 0.5),
        _TopicWord(text: '数据基建', size: 13, weight: 0.45),
        _TopicWord(text: '安全', size: 15, weight: 0.55),
      ],
    );
  }
}

class _TopicWord extends StatelessWidget {
  const _TopicWord({
    required this.text,
    required this.size,
    required this.weight,
  });

  final String text;
  final double size;
  final double weight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lightness = 0.45 + weight * 0.4;
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: HSLColor.fromColor(colors.primary)
            .withLightness(lightness.clamp(0.3, 0.7))
            .toColor(),
      ),
    );
  }
}
