import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'devintel_demo.dart';

class DevIntelHotspotList extends StatelessWidget {
  const DevIntelHotspotList({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.lg)),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '技术热点',
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '趋势增长分类',
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < kDevIntelHotspots.length; i++) ...[
            _HotspotTile(hotspot: kDevIntelHotspots[i]),
            if (i != kDevIntelHotspots.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _HotspotTile extends StatelessWidget {
  const _HotspotTile({required this.hotspot});

  final DevIntelHotspot hotspot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hotspot.color.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.sm + 2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            hotspot.abbr,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: hotspot.color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hotspot.name.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _HotspotBadge(text: hotspot.tag, color: hotspot.color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressBar(
                value: hotspot.progress,
                color: hotspot.color,
                track: colors.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotspotBadge extends StatelessWidget {
  const _HotspotBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.xs)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(2)),
      child: Stack(
        children: [
          Container(height: 4, color: track),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: 4, color: color),
          ),
        ],
      ),
    );
  }
}
