import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/discover_entities.dart';
import 'discover_profile_metrics.dart';

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
    final l10n = AppLocalizations.of(context);
    final labelKey = profile.kind == DiscoverProfileKind.official ? 'discover.profile.official' : 'discover.profile.people';
    if (!cardStyle) {
      return _CompactProfileRow(profile: profile, onTap: onTap, label: l10n.tr(labelKey));
    }
    return _CardProfileRow(profile: profile, onTap: onTap, label: l10n.tr(labelKey));
  }
}

class _CompactProfileRow extends StatelessWidget {
  const _CompactProfileRow({required this.profile, required this.label, this.onTap});

  final DiscoverProfileEntity profile;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                        style: AppTypography.titleSmall.copyWith(color: colors.onSurface),
                      )),
                      DiscoverProfileMetricPill(text: label, color: colors.primary)
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('@${profile.login}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                  if (profile.enriched && profile.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    )
                  ] else if (!profile.enriched) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text('—', style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.5)))
                  ],
                  const SizedBox(height: AppSpacing.xs2),
                  Row(
                    children: [
                      DiscoverProfileIconMetric(
                        icon: Icons.group_rounded,
                        value: l10n.tr('discover.profile.followers').replaceAll('{n}', placeholderOrNumber(profile.followers, profile.enriched)),
                        color: colors.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      DiscoverProfileIconMetric(
                        icon: Icons.folder_rounded,
                        value: l10n.tr('discover.profile.repos').replaceAll('{n}', placeholderOrNumber(profile.publicRepos, profile.enriched)),
                        color: colors.secondary,
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.onSurfaceVariant)
          ],
        ),
      ),
    );
  }
}

class _CardProfileRow extends StatelessWidget {
  const _CardProfileRow({required this.profile, required this.label, this.onTap});

  final DiscoverProfileEntity profile;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = profile.kind == DiscoverProfileKind.official ? colors.primary : AppColors.accentPurple;
    final l10n = AppLocalizations.of(context);
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
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1))),
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
                            style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DiscoverProfileMetricPill(text: label, color: accent)
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('@${profile.login}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                    if (profile.enriched && profile.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant, height: 1.55),
                      )
                    ] else if (!profile.enriched) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('—', style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.5), height: 1.55))
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DiscoverProfileMetricPill(text: profile.featuredRepoFullName, color: colors.secondary),
                        DiscoverProfileIconMetric(
                          icon: Icons.group_rounded,
                          value: l10n.tr('discover.profile.followers').replaceAll('{n}', placeholderOrNumber(profile.followers, profile.enriched)),
                          color: colors.tertiary,
                        ),
                        DiscoverProfileIconMetric(
                          icon: Icons.folder_rounded,
                          value: l10n.tr('discover.profile.repos').replaceAll('{n}', placeholderOrNumber(profile.publicRepos, profile.enriched)),
                          color: colors.secondary,
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, size: 18, color: colors.onSurfaceVariant)
            ],
          ),
        ),
      ),
    );
  }
}
