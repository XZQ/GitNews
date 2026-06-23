import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelHotspotList extends StatelessWidget {
  const DevIntelHotspotList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tech Hotspots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Trending categories with momentum',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMutedDark,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hotspot.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            hotspot.abbr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: hotspot.color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _HotspotBadge(tag: hotspot.tag, color: hotspot.color),
                ],
              ),
              const SizedBox(height: 8),
              _ProgressBar(value: hotspot.progress, color: hotspot.color),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotspotBadge extends StatelessWidget {
  const _HotspotBadge({required this.tag, required this.color});

  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
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
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Stack(
        children: [
          Container(height: 4, color: const Color(0xFF23232B)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: 4, color: color),
          ),
        ],
      ),
    );
  }
}
