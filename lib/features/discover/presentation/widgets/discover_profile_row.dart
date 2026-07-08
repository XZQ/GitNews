import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/discover_entities.dart';

class DiscoverProfileRow extends StatelessWidget {
  const DiscoverProfileRow({
    required this.profile,
    this.onTap,
    super.key,
  });

  final DiscoverProfileEntity profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final labelKey = profile.kind == DiscoverProfileKind.official
        ? 'discover.profile.official'
        : 'discover.profile.people';
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
              backgroundImage: profile.avatarUrl.isEmpty
                  ? null
                  : NetworkImage(profile.avatarUrl),
              child: profile.avatarUrl.isEmpty
                  ? Text(profile.login.characters.first.toUpperCase())
                  : null,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          l10n.tr(labelKey),
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '@${profile.login}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs2),
                  Row(
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 13,
                        color: colors.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l10n.tr('discover.profile.followers').replaceAll(
                              '{n}',
                              _shortNumber(profile.followers),
                            ),
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.folder_rounded,
                        size: 13,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l10n.tr('discover.profile.repos').replaceAll(
                              '{n}',
                              _shortNumber(profile.publicRepos),
                            ),
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

String _shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}
