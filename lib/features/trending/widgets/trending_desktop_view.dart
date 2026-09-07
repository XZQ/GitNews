import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_growth_chart.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import 'trending_board_selector.dart';
import 'trending_language_panel.dart';
import 'trending_list.dart';
import 'trending_page_header.dart';
import 'trending_topics_panel.dart';

/* 
*桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
*/
class TrendingDesktopView extends ConsumerWidget {
  const TrendingDesktopView({required this.digest, this.isReloading = false, super.key});

  final TrendingDigest digest;
  final bool isReloading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(trendingWindowFilterProvider);
    final lang = ref.watch(trendingLanguageFilterProvider);
    final board = ref.watch(trendingBoardFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrendingPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrendingBoardSelector(value: board, onChanged: (value) => ref.read(trendingBoardFilterProvider.notifier).state = value),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(title: l10n.tr('growth.title'), subtitle: l10n.tr('growth.subtitle')),
                      const SizedBox(height: AppSpacing.md),
                      RepaintBoundary(
                        child: RepoGrowthChart(
                          repos: digest.allRepos,
                          days: window == 'today'
                              ? 1
                              : window == 'week'
                              ? 7
                              : 30,
                          height: 180,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 320).clamp(220.0, 900.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 8,
                        child: TrendingList(repos: digest.trendingRepos, isLoading: isReloading),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TrendingLanguagePanel(value: lang, onChanged: (v) => ref.read(trendingLanguageFilterProvider.notifier).state = v, languages: digest.languages),
                              const SizedBox(height: AppSpacing.lg),
                              const TrendingTopicsPanel(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
