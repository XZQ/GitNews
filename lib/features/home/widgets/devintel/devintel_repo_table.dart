import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelRepoTable extends StatelessWidget {
  const DevIntelRepoTable({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.t('devintel.repoTableTitle'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _HeaderRow(t: t),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.outlineVariant, height: 1),
          for (var i = 0; i < kDevIntelRepoRows.length; i++) ...[
            if (i != 0) Divider(color: colors.outlineVariant, height: 1),
            _RepoRowTile(row: kDevIntelRepoRows[i], t: t),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.t});

  final AppStrings t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colors.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    return Row(
      children: [
        SizedBox(
            width: 32, child: Text(t.t('devintel.col.rank'), style: style)),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(t.t('devintel.col.repository'), style: style),
        ),
        SizedBox(
          width: 100,
          child: Text(t.t('devintel.col.category'), style: style),
        ),
        SizedBox(
          width: 80,
          child: Text(
            t.t('devintel.col.lang'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            t.t('devintel.col.newStars'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            t.t('devintel.col.total'),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _RepoRowTile extends StatelessWidget {
  const _RepoRowTile({required this.row, required this.t});

  final DevIntelRepoRow row;
  final AppStrings t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(
        '/repo_detail/${Uri.encodeComponent(row.name)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: row.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  row.rank,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: row.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(
                row.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child:
                  _CategoryBadge(text: t.t(row.categoryKey), color: row.color),
            ),
            SizedBox(
              width: 80,
              child: Text(
                row.lang,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                row.newStars,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                row.total,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
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
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
