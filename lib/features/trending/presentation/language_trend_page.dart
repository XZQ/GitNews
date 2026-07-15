import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import '../widgets/language_donut_chart.dart';
import '../widgets/language_growth_bars.dart';

/*
*二级页 2:语言趋势(饼图 + 列表)。
*/
class LanguageTrendPage extends ConsumerWidget {
  const LanguageTrendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(trendingDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('trending.language_trend.title')),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/trending'),
        ),
      ),
      body: state.when(
        data: (digest) {
          if (digest.languages.isEmpty) {
            return EmptyView(icon: Icons.code_rounded, message: l10n.tr('trending.language_trend.empty'));
          }
          return ResponsiveLayout(
            compact: (_) => _Body(digest: digest),
            medium: (_) => CenteredContent(child: _Body(digest: digest)),
            expanded: (_) => CenteredContent(child: _Body(digest: digest)),
          );
        },
        loading: () => const _PageSkeleton(),
        error: (error, stackTrace) => ErrorView(
          error: AppException(
            kind: AppExceptionKind.unknown,
            cause: error,
            stack: stackTrace,
          ),
          onRetry: () => ref.invalidate(trendingDigestProvider),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.digest});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.tr('trending.language_trend.overview_title'),
                subtitle: l10n.tr('trending.language_trend.overview_subtitle'),
              ),
              const SizedBox(height: AppSpacing.lg),
              LanguageDonutChart(
                data: digest.languages,
                holeColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final l in digest.languages) ...[
                LanguageDistributionRow(
                  name: l.name,
                  percent: l.percent,
                  delta: l.delta,
                  color: Color(l.accentArgb),
                ),
                const SizedBox(height: AppSpacing.sm2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('trending.language_trend.growth_title'), subtitle: l10n.tr('trending.language_trend.growth_subtitle')),
              const SizedBox(height: AppSpacing.md),
              LanguageGrowthBars(languages: digest.languages),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Skeleton(height: 360),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 240),
        ],
      ),
    );
  }
}
