import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trending/application/trending_providers.dart';

class DevIntelRepoTable extends ConsumerWidget {
  const DevIntelRepoTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final rows = ref.watch(trendingDigestProvider).maybeWhen(
          data: (digest) => digest.allRepos.take(6).toList(),
          orElse: () => const <RepoEntity>[],
        );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.tr('home.repo_table.title'),
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HeaderRow(),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.outlineVariant, height: 1),
          for (var i = 0; i < rows.length; i++) ...[
            if (i != 0) Divider(color: colors.outlineVariant, height: 1),
            _RepoRowTile(repo: rows[i], rank: i + 1),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final style = AppTypography.labelMicro.copyWith(
      color: colors.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(l10n.tr('home.repo_table.col_rank'), style: style),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 5,
          child: Text(l10n.tr('home.repo_table.col_repo'), style: style),
        ),
        SizedBox(
          width: 100,
          child: Text(l10n.tr('home.repo_table.col_category'), style: style),
        ),
        SizedBox(
          width: 80,
          child: Text(
            l10n.tr('home.repo_table.col_lang'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            l10n.tr('home.repo_table.col_new_stars'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            l10n.tr('home.repo_table.col_total'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _RepoRowTile extends StatelessWidget {
  const _RepoRowTile({required this.repo, required this.rank});

  final RepoEntity repo;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = Color(repo.accentArgb);
    return InkWell(
      onTap: () => context.go(
        '/home/detail/${Uri.encodeComponent(repo.fullName)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 5,
              child: Text(
                repo.fullName,
                style: AppTypography.labelLarge.copyWith(
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: _CategoryBadge(text: _category(repo), color: color),
            ),
            SizedBox(
              width: 80,
              child: Text(
                repo.language,
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                '+${_compactNumber(repo.starDelta)}',
                textAlign: TextAlign.right,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                _compactNumber(repo.starCount),
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _category(RepoEntity repo) {
    final text = '${repo.fullName} ${repo.description}'.toLowerCase();
    if (text.contains('agent') || text.contains('langchain')) return 'Agent';
    if (text.contains('mcp') || text.contains('context')) return 'MCP';
    if (text.contains('code') || text.contains('coding')) return 'AI Coding';
    if (text.contains('rag') || text.contains('vector')) return 'RAG';
    return '开源项目';
  }

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: AppTypography.labelMicro.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
