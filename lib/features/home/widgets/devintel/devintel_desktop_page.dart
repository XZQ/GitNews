import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'devintel_bottom_grid.dart';
import 'devintel_chart_card.dart';
import 'devintel_metric_strip.dart';
import 'devintel_sidebar.dart';
import 'devintel_top_header.dart';

class DevIntelDesktopPage extends StatelessWidget {
  const DevIntelDesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Row(
        children: [
          const DevIntelSidebar(),
          const VerticalDivider(width: 1, color: Color(0xFF2A2A30)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DevIntelTopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      20,
                      AppSpacing.xl,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
          ),
        ],
      ),
    );
  }
}
