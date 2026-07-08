import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../tech_hotspot/domain/tech_hotspot_models.dart';

class DevIntelHotspotList extends ConsumerWidget {
  const DevIntelHotspotList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final topics = ref.watch(techHotspotDigestProvider).maybeWhen(
          data: (digest) => digest.topics.take(4).toList(),
          orElse: () => const <TechTopic>[],
        );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.tr('tech_hotspot.title'),
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tr('home.section.hotspot.subtitle'),
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < topics.length; i++) ...[
            _HotspotTile(topic: topics[i]),
            if (i != topics.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _HotspotTile extends StatelessWidget {
  const _HotspotTile({required this.topic});

  final TechTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _heatColor(topic.heat);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          alignment: Alignment.center,
          child: Text(
            _abbr(topic.name),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
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
                      topic.name.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _HotspotBadge(text: topic.category, color: color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressBar(
                value: topic.heat / 100,
                color: color,
                track: colors.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _abbr(String name) {
    final letters = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.characters.first)
        .take(3)
        .join();
    return letters.isEmpty ? 'AI' : letters.toUpperCase();
  }

  Color _heatColor(int heat) {
    if (heat >= 90) return AppColors.danger;
    if (heat >= 75) return AppColors.warning;
    return AppColors.info;
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
        horizontal: AppSpacing.xs2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs)),
      ),
      child: Text(
        text,
        style: AppTypography.labelMicro.copyWith(
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
