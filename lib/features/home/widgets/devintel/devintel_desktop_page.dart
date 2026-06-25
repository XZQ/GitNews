import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'devintel_bottom_grid.dart';
import 'devintel_chart_card.dart';
import 'devintel_metric_strip.dart';
import 'devintel_top_header.dart';

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
                20,
                AppSpacing.xl,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DevIntelMetricStrip(),
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
