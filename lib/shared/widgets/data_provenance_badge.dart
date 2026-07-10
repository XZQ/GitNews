import 'package:flutter/material.dart';

import '../../core/domain/data_freshness.dart';
import '../../core/domain/data_provenance.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class DataProvenanceBadge extends StatelessWidget {
  const DataProvenanceBadge({
    required this.provenance,
    this.compact = true,
    this.inverse = false,
    super.key,
  });

  final DataProvenance provenance;
  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _TrustBadge(
      label: compact ? _shortLabel(l10n) : _fullLabel(l10n),
      tooltip: _tooltip(l10n),
      color: _color(context),
      compact: compact,
      inverse: inverse,
    );
  }

  String _shortLabel(AppLocalizations l10n) {
    return switch (provenance) {
      DataProvenance.live => l10n.tr('provenance.live'),
      DataProvenance.freshCache => l10n.tr('provenance.fresh_cache'),
      DataProvenance.staleCache => l10n.tr('provenance.stale_cache'),
      DataProvenance.estimated => l10n.tr('provenance.estimated'),
      DataProvenance.seed => l10n.tr('provenance.seed'),
    };
  }

  String _fullLabel(AppLocalizations l10n) {
    return switch (provenance) {
      DataProvenance.live => l10n.tr('provenance.live.full'),
      DataProvenance.freshCache => l10n.tr('provenance.fresh_cache.full'),
      DataProvenance.staleCache => l10n.tr('provenance.stale_cache.full'),
      DataProvenance.estimated => l10n.tr('provenance.estimated.full'),
      DataProvenance.seed => l10n.tr('provenance.seed.full'),
    };
  }

  String _tooltip(AppLocalizations l10n) {
    return switch (provenance) {
      DataProvenance.live => l10n.tr('provenance.live.tooltip'),
      DataProvenance.freshCache => l10n.tr('provenance.fresh_cache.tooltip'),
      DataProvenance.staleCache => l10n.tr('provenance.stale_cache.tooltip'),
      DataProvenance.estimated => l10n.tr('provenance.estimated.tooltip'),
      DataProvenance.seed => l10n.tr('provenance.seed.tooltip'),
    };
  }

  Color _color(BuildContext context) {
    return switch (provenance) {
      DataProvenance.live => AppColors.success,
      DataProvenance.freshCache => AppColors.info,
      DataProvenance.staleCache => AppColors.warning,
      DataProvenance.estimated => AppColors.accentPurple,
      DataProvenance.seed => Theme.of(context).colorScheme.outline,
    };
  }
}

class DataFreshnessBadge extends StatelessWidget {
  const DataFreshnessBadge({
    required this.freshness,
    this.compact = true,
    this.inverse = false,
    super.key,
  });

  final DataFreshness freshness;
  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keys = switch (freshness) {
      DataFreshness.live => (
          'provenance.live',
          'provenance.live.full',
          'provenance.live.tooltip',
        ),
      DataFreshness.freshCache => (
          'provenance.fresh_cache',
          'provenance.fresh_cache.full',
          'provenance.fresh_cache.tooltip',
        ),
      DataFreshness.staleCache => (
          'provenance.stale_cache',
          'provenance.stale_cache.full',
          'provenance.stale_cache.tooltip',
        ),
      DataFreshness.seed => (
          'provenance.seed',
          'provenance.seed.full',
          'provenance.seed.tooltip',
        ),
    };
    final color = switch (freshness) {
      DataFreshness.live => AppColors.success,
      DataFreshness.freshCache => AppColors.info,
      DataFreshness.staleCache => AppColors.warning,
      DataFreshness.seed => Theme.of(context).colorScheme.outline,
    };
    return _TrustBadge(
      label: l10n.tr(compact ? keys.$1 : keys.$2),
      tooltip: l10n.tr(keys.$3),
      color: color,
      compact: compact,
      inverse: inverse,
    );
  }
}

class MetricBasisBadge extends StatelessWidget {
  const MetricBasisBadge({
    required this.basis,
    this.compact = true,
    this.inverse = false,
    super.key,
  });

  final MetricBasis basis;
  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keys = switch (basis) {
      MetricBasis.observed => (
          'basis.observed',
          'basis.observed.full',
          'basis.observed.tooltip',
        ),
      MetricBasis.estimated => (
          'provenance.estimated',
          'provenance.estimated.full',
          'provenance.estimated.tooltip',
        ),
      MetricBasis.seed => (
          'provenance.seed',
          'provenance.seed.full',
          'provenance.seed.tooltip',
        ),
    };
    final color = switch (basis) {
      MetricBasis.observed => AppColors.success,
      MetricBasis.estimated => AppColors.accentPurple,
      MetricBasis.seed => Theme.of(context).colorScheme.outline,
    };
    return _TrustBadge(
      label: l10n.tr(compact ? keys.$1 : keys.$2),
      tooltip: l10n.tr(keys.$3),
      color: color,
      compact: compact,
      inverse: inverse,
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.compact,
    required this.inverse,
  });

  final String label;
  final String tooltip;
  final Color color;
  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs2 : AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: inverse ? Colors.white.withValues(alpha: 0.18) : color.withValues(alpha: 0.1),
          border: Border.all(
            color: inverse ? Colors.white.withValues(alpha: 0.28) : color.withValues(alpha: 0.28),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.labelMicro.copyWith(
            color: inverse ? Colors.white : color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
