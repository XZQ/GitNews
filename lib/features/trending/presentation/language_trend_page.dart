import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/// 二级页 2:语言趋势(饼图 + 列表)。
class LanguageTrendPage extends StatelessWidget {
  const LanguageTrendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言趋势'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trending'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(child: _Body()),
        expanded: (_) => const CenteredContent(child: _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
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
              const SectionHeader(
                title: '语言趋势总览',
                subtitle: '热门仓库的编程语言占比 · 最近 30 天',
              ),
              const SizedBox(height: AppSpacing.lg),
              _DonutChart(
                holeColor:
                    isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final l in DemoData.languages) ...[
                _LangRow(
                  name: l.name,
                  percent: l.percent,
                  delta: l.delta,
                  color: Color(l.color),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '语言增长率排行',
                subtitle: '本周 vs 上周',
              ),
              SizedBox(height: AppSpacing.md),
              _GrowthBars(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.holeColor});
  final Color holeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _DonutPainter(
          data: DemoData.languages,
          holeColor: holeColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '2.36M',
                style: AppTypography.displayMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '总 Star 增长',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.data, required this.holeColor});
  final List<DemoLanguage> data;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - 12;
    final center = Offset(size.width / 2, size.height / 2);
    var start = -3.14159 / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final l in data) {
      final sweep = (l.percent / 100) * 6.28318;
      paint.color = Color(l.color);
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
        )
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, paint);
      start += sweep;
    }
    paint.color = holeColor;
    canvas.drawCircle(center, radius * 0.62, paint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.data != data || old.holeColor != holeColor;
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
  });

  final String name;
  final double percent;
  final double delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: AppTypography.titleSmall),
        ),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(width: 8),
        Text(
          '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
          style: AppTypography.labelSmall.copyWith(
            color: delta >= 0 ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GrowthBars extends StatelessWidget {
  const _GrowthBars();

  @override
  Widget build(BuildContext context) {
    final maxV =
        DemoData.languages.map((l) => l.delta).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final l in DemoData.languages) ...[
          _Bar(
            name: l.name,
            value: l.delta,
            maxValue: maxV,
            color: Color(l.color),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.name,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String name;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(name, style: AppTypography.labelMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 16,
                  color: colors.surfaceContainerHighest,
                ),
                FractionallySizedBox(
                  widthFactor: (value / maxValue).clamp(0.0, 1.0),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: AppTypography.labelSmall.copyWith(
              color: value >= 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
