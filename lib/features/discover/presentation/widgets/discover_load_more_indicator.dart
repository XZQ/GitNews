import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class DiscoverLoadMoreIndicator extends StatelessWidget {
  const DiscoverLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Center(child: CircularProgressIndicator()));
  }
}
