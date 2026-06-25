import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/mock_tech_hotspot.dart';
import 'widgets/tech_hotspot_heat_chart.dart';
import 'widgets/tech_hotspot_language_panel.dart';
import 'widgets/tech_hotspot_page_header.dart';
import 'widgets/tech_hotspot_topic_card.dart';

/// 技术热点页(桌面 / Expanded)。
///
/// 结构:
/// - 顶部条 [TechHotspotPageHeader]
/// - 行 1:热度曲线(8) + 语言占比(4)
/// - 行 2:主题网格(2 列)
/// - 行 3:热门标签云
class TechHotspotPage extends StatelessWidget {
  const TechHotspotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechHotspotPageHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopRow(),
                  SizedBox(height: AppSpacing.lg),
                  _TopicGrid(),
                  SizedBox(height: AppSpacing.lg),
                  _TagsCloud(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: TechHotspotHeatChart()),
          SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: TechHotspotLanguagePanel()),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid();

  @override
  Widget build(BuildContext context) {
    const topics = MockTechHotspot.topics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < topics.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < topics.length ? AppSpacing.lg : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TechHotspotTopicCard(topic: topics[i], onTap: () {}),
                ),
                if (i + 1 < topics.length) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: TechHotspotTopicCard(
                      topic: topics[i + 1],
                      onTap: () {},
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _TagsCloud extends StatelessWidget {
  const _TagsCloud();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '热门标签',
                style: AppTypography.titleSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in MockTechHotspot.hotTags) _Tag(label: tag),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '# $label',
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
