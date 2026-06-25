import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/bordered_row.dart';
import 'devintel_hotspot_list.dart';
import 'devintel_monitoring_status.dart';
import 'devintel_repo_table.dart';
import 'devintel_signals_list.dart';

class DevIntelBottomGrid extends StatelessWidget {
  const DevIntelBottomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BorderedRow(
          flexValues: [7, 5],
          children: [DevIntelRepoTable(), DevIntelHotspotList()],
        ),
        SizedBox(height: AppSpacing.lg),
        BorderedRow(
          flexValues: [7, 5],
          children: [DevIntelSignalsList(), DevIntelMonitoringStatus()],
        ),
      ],
    );
  }
}
