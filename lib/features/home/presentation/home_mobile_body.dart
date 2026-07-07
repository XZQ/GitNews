import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../trending/application/trending_providers.dart';
import '../widgets/home_alerts_panel.dart';
import '../widgets/home_topics_panel.dart';
import 'home_chart_helpers.dart';

/* 
*Home compact (<600) 分支:Hero 趋势 + 告警 + 主题。
*/
class HomeMobileBody extends StatelessWidget {
  const HomeMobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        _MobileHero(),
        SizedBox(height: AppSpacing.lg),
        HomeAlertsPanel(showHeader: true, maxItems: 5),
        SizedBox(height: AppSpacing.lg),
        HomeTopicsPanel(),
      ],
    );
  }
}

class _MobileHero extends ConsumerStatefulWidget {
  const _MobileHero();

  @override
  ConsumerState<_MobileHero> createState() => _MobileHeroState();
}

class _MobileHeroState extends ConsumerState<_MobileHero> {
  int _window = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digest = ref.watch(trendingDigestProvider).valueOrNull;
    final series = homeSeriesForWindow(
      _window,
      HomeLegacyTab.trending,
      Theme.of(context).colorScheme.primary,
      primaryTrend: digest?.primaryTrend,
      secondaryTrend: digest?.secondaryTrend,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tr('home.chart.title'),
                  style: AppTypography.titleLarge,
                ),
              ),
              ChartWindowSegmented(
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$_window ${l10n.tr('common.day')}',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(series: series, height: 200),
        ],
      ),
    );
  }
}
