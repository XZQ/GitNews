import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'devintel_hotspot_list.dart';
import 'devintel_monitoring_status.dart';
import 'devintel_repo_table.dart';
import 'devintel_signals_list.dart';

class DevIntelBottomGrid extends StatelessWidget {
  const DevIntelBottomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(flex: 7, child: DevIntelRepoTable()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: DevIntelHotspotList()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(flex: 7, child: DevIntelSignalsList()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: DevIntelMonitoringStatus()),
            ],
          ),
        ),
      ],
    );
  }
}
