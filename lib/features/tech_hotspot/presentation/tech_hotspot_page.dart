import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../application/tech_hotspot_providers.dart';
import '../domain/tech_hotspot_models.dart';
import 'widgets/tech_hotspot_heat_chart.dart';
import 'widgets/tech_hotspot_language_panel.dart';
import 'widgets/tech_hotspot_page_header.dart';
import 'widgets/tech_hotspot_topic_card.dart';

/// 技术趋势页(桌面 / Expanded)。
///
/// 结构:
/// - 顶部条 [TechHotspotPageHeader]
/// - 行 1:热门标签云
/// - 行 2:热度曲线(8) + 语言占比(4)
/// - 行 3:主题网格(2 列)
class TechHotspotPage extends ConsumerWidget {
  const TechHotspotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(techHotspotDigestProvider);
    final isCompact = Breakpoints.of(context) == FormFactor.compact;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TechHotspotPageHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? AppSpacing.lg : AppSpacing.xl,
                AppSpacing.lg,
                isCompact ? AppSpacing.lg : AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TagsCloud(tags: digest.hotTags),
                  const SizedBox(height: AppSpacing.lg),
                  _TopRow(digest: digest),
                  const SizedBox(height: AppSpacing.lg),
                  _TopicGrid(topics: digest.topics),
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
  const _TopRow({required this.digest});

  final TechHotspotDigest digest;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    if (formFactor == FormFactor.expanded) {
      return SizedBox(
        height: 280,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 8,
              child: TechHotspotHeatChart(values: digest.heatTrend),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: TechHotspotLanguagePanel(languages: digest.languages),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: TechHotspotHeatChart(values: digest.heatTrend),
        ),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotLanguagePanel(languages: digest.languages),
      ],
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics});

  final List<TechTopic> topics;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    final crossAxisCount = formFactor == FormFactor.expanded ? 2 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < topics.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + crossAxisCount < topics.length ? AppSpacing.lg : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < crossAxisCount; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: i + j < topics.length
                        ? TechHotspotTopicCard(
                            topic: topics[i + j],
                            onTap: () => context.go(
                              '/tech_hotspot/detail/${topics[i + j].id}',
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TagsCloud extends StatelessWidget {
  const _TagsCloud({required this.tags});

  final List<String> tags;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              for (final tag in tags) _Tag(label: tag),
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
