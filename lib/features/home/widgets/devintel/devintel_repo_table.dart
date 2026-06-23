import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'devintel_demo.dart';

class DevIntelRepoTable extends StatelessWidget {
  const DevIntelRepoTable({super.key});

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
            "Today's Hot Repositories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HeaderRow(),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Color(0xFF2A2A30), height: 1),
          for (var i = 0; i < kDevIntelRepoRows.length; i++) ...[
            if (i != 0) const Divider(color: Color(0xFF1F1F25), height: 1),
            _RepoRowTile(row: kDevIntelRepoRows[i]),
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
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textMutedDark,
      letterSpacing: 0.6,
    );
    return Row(
      children: [
        const SizedBox(width: 32, child: Text('RANK', style: style)),
        const SizedBox(width: 12),
        const Expanded(
          flex: 5,
          child: Text('REPOSITORY', style: style),
        ),
        const SizedBox(
          width: 100,
          child: Text('CATEGORY', style: style),
        ),
        const SizedBox(
          width: 80,
          child: Text(
            'LANG',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        const SizedBox(
          width: 90,
          child: Text(
            'NEW STARS',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        const SizedBox(
          width: 70,
          child: Text(
            'TOTAL',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _RepoRowTile extends StatelessWidget {
  const _RepoRowTile({required this.row});

  final DevIntelRepoRow row;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: _CategoryBadge(text: row.category, color: row.color),
            ),
            SizedBox(
              width: 80,
              child: Text(
                row.lang,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
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
