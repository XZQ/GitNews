import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/*
*少量指标卡的自适应网格。
*
*窄内容区使用两列，宽内容区使用四列；每一行按最高卡片自然高度拉齐，
*避免固定高度在系统大字体或长文案下产生溢出。
*/
class AdaptiveMetricGrid extends StatelessWidget {
  const AdaptiveMetricGrid({
    required this.children,
    this.compactMaxWidth = 520,
    this.compactColumns = 2,
    this.expandedColumns = 4,
    this.spacing = AppSpacing.sm,
    super.key,
  });

  // 按显示顺序排列的指标卡。
  final List<Widget> children;

  // 小于该内容宽度时切换到紧凑列数。
  final double compactMaxWidth;

  // 紧凑内容区的列数。
  final int compactColumns;

  // 宽内容区的列数。
  final int expandedColumns;

  // 行列间距。
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final requestedColumns = constraints.maxWidth < compactMaxWidth ? compactColumns : expandedColumns;
        final columnCount = math.min(requestedColumns, children.length);
        final rowCount = (children.length / columnCount).ceil();
        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              if (rowIndex != 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) ...[
                      if (columnIndex != 0) SizedBox(width: spacing),
                      Expanded(
                        child: rowIndex * columnCount + columnIndex < children.length ? children[rowIndex * columnCount + columnIndex] : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
