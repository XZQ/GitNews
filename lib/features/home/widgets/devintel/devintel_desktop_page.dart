import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/bordered_row.dart';
import 'devintel_bottom_grid.dart';
import 'devintel_chart_card.dart';
import 'devintel_top_header.dart';
import 'home_ai_news_preview.dart';
import 'home_hotspot_preview.dart';
import 'home_section_entry_row.dart';
import 'home_trending_preview.dart';

/* 首页(桌面 / Expanded)情报总览。 */
/*  */
/* 三行布局: */
/* - Row 1:[HomeSectionEntryRow] — 5 栏目入口 + KPI */
/* - Row 2:3 列 [HomeAiNewsPreview] / [HomeTrendingPreview] / [HomeHotspotPreview] */
/* - Row 3:[DevIntelChartCard] + [DevIntelBottomGrid] — Star 趋势与监控状态 */
class DevIntelDesktopPage extends StatelessWidget {
  const DevIntelDesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DevIntelTopHeader(),
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
                  HomeSectionEntryRow(),
                  SizedBox(height: AppSpacing.lg),
                  _PreviewRow(),
                  SizedBox(height: AppSpacing.lg),
                  DevIntelChartCard(),
                  SizedBox(height: AppSpacing.lg),
                  DevIntelBottomGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow();

  @override
  Widget build(BuildContext context) {
    return const BorderedRow(
      flexValues: [4, 4, 4],
      children: [
        HomeAiNewsPreview(),
        HomeTrendingPreview(),
        HomeHotspotPreview(),
      ],
    );
  }
}
