import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/discover_entities.dart';

class DiscoverProfileRow extends StatelessWidget {
  const DiscoverProfileRow({
    required this.profile,
    this.onTap,
    this.cardStyle = true,
    super.key,
  });

  final DiscoverProfileEntity profile;
  final VoidCallback? onTap;
  final bool cardStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context);
    final labelKey = profile.kind == DiscoverProfileKind.official ? 'discover.profile.official' : 'discover.profile.people';
    final accent = profile.kind == DiscoverProfileKind.official ? colors.primary : AppColors.accentPurple;
    if (!cardStyle) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                backgroundImage: profile.avatarUrl.isEmpty ? null : NetworkImage(profile.avatarUrl),
                child: profile.avatarUrl.isEmpty ? Text(profile.login.characters.first.toUpperCase()) : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        _Pill(text: l10n.tr(labelKey), color: colors.primary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '@${profile.login}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (profile.enriched && profile.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ] else if (!profile.enriched) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '—',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs2),
                    Row(
                      children: [
                        _IconMetric(
                          icon: Icons.group_rounded,
                          value: l10n.tr('discover.profile.followers').replaceAll(
                                '{n}',
                                _placeholderOrNumber(profile.followers, profile.enriched),
                              ),
                          color: colors.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _IconMetric(
                          icon: Icons.folder_rounded,
                          value: l10n.tr('discover.profile.repos').replaceAll(
                                '{n}',
                                _placeholderOrNumber(profile.publicRepos, profile.enriched),
                              ),
                          color: colors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                backgroundImage: profile.avatarUrl.isEmpty ? null : NetworkImage(profile.avatarUrl),
                child: profile.avatarUrl.isEmpty ? Text(profile.login.characters.first.toUpperCase()) : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _Pill(
                          text: l10n.tr(labelKey),
                          color: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@${profile.login}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (profile.enriched && profile.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ] else if (!profile.enriched) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '—',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                          height: 1.55,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(
                          text: profile.featuredRepoFullName,
                          color: colors.secondary,
                        ),
                        _IconMetric(
                          icon: Icons.group_rounded,
                          value: l10n.tr('discover.profile.followers').replaceAll(
                                '{n}',
                                _placeholderOrNumber(profile.followers, profile.enriched),
                              ),
                          color: colors.tertiary,
                        ),
                        _IconMetric(
                          icon: Icons.folder_rounded,
                          value: l10n.tr('discover.profile.repos').replaceAll(
                                '{n}',
                                _placeholderOrNumber(profile.publicRepos, profile.enriched),
                              ),
                          color: colors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _shortNumber(int value) => switch (value) {
      >= 1000000 => '${(value / 1000000).toStringAsFixed(1)}M',
      >= 1000 => '${(value / 1000).toStringAsFixed(1)}k',
      _ => value.toString(),
    };

String _placeholderOrNumber(int value, bool enriched) => enriched ? _shortNumber(value) : '—';
