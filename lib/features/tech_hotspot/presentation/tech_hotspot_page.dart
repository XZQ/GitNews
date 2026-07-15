import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/tech_hotspot_providers.dart';
import '../domain/tech_hotspot_models.dart';
import 'widgets/tech_hotspot_agent_signal_board.dart';
import 'widgets/tech_hotspot_heat_chart.dart';
import 'widgets/tech_hotspot_language_panel.dart';
import 'widgets/tech_hotspot_page_header.dart';
import 'widgets/tech_hotspot_tags_cloud.dart';
import 'widgets/tech_hotspot_topic_card.dart';

/* 
*AI 雷达页(桌面 / Expanded)。
*结构:
*- 顶部条 [TechHotspotPageHeader]
*- 行 1:雷达标签云
*- 行 2:Agent 榜观察
*- 行 2:热度曲线(8) + 语言占比(4)
*- 行 3:主题网格(2 列)
*/
class TechHotspotPage extends ConsumerWidget {
  const TechHotspotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredTechHotspotDigestProvider);
    return Scaffold(
      body: state.when(
        data: (digest) => _Body(digest: digest),
        loading: () => const _TechHotspotSkeleton(),
        error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(techHotspotDigestProvider)),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.digest});

  final TechHotspotDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.of(context) == FormFactor.compact;
    return Column(
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
                TechHotspotTagsCloud(tags: digest.hotTags, onTagSelected: (tag) => ref.read(techHotspotSearchQueryProvider.notifier).state = tag),
                const SizedBox(height: AppSpacing.lg),
                TechHotspotAgentSignalBoard(topics: digest.topics),
                const SizedBox(height: AppSpacing.lg),
                _TopRow(digest: digest),
                const SizedBox(height: AppSpacing.lg),
                _TopicGrid(topics: digest.topics)
              ],
            ),
          ),
        )
      ],
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
        height: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 8, child: TechHotspotHeatChart(values: digest.heatTrend)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: TechHotspotLanguagePanel(languages: digest.languages))
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SizedBox(height: 260, child: TechHotspotHeatChart(values: digest.heatTrend)), const SizedBox(height: AppSpacing.lg), TechHotspotLanguagePanel(languages: digest.languages)],
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics});

  final List<TechTopic> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return EmptyView(icon: Icons.search_off_rounded, message: AppLocalizations.of(context).tr('tech_hotspot.empty.topics'));
    }

    final formFactor = Breakpoints.of(context);
    final crossAxisCount = formFactor == FormFactor.expanded ? 2 : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < topics.length; i += crossAxisCount)
        Padding(
            padding: EdgeInsets.only(bottom: i + crossAxisCount < topics.length ? AppSpacing.lg : 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var j = 0; j < crossAxisCount; j++) ...[
                if (j > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(child: i + j < topics.length ? TechHotspotTopicCard(topic: topics[i + j], onTap: () => context.go('/tech_hotspot/detail/${topics[i + j].id}')) : const SizedBox())
              ]
            ]))
    ]);
  }
}

class _TechHotspotSkeleton extends StatelessWidget {
  const _TechHotspotSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: const [Skeleton(height: 92), SizedBox(height: AppSpacing.lg), Skeleton(height: 280), SizedBox(height: AppSpacing.lg), Skeleton(height: 320)],
    );
  }
}
