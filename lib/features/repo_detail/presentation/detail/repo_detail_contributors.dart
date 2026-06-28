import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/demo_data.dart';

class RepoDetailContributors extends StatelessWidget {
  const RepoDetailContributors({required this.contributors, super.key});

  final List<DemoContributor> contributors;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '贡献者活跃度',
            subtitle: '本周贡献排行',
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final c in contributors) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        Color(c.avatarColor).withValues(alpha: 0.16),
                    child: Text(
                      c.login[0].toUpperCase(),
                      style: AppTypography.titleSmall.copyWith(
                        color: Color(c.avatarColor),
                      ),
                    ),
                  ),
                  title: Text(c.login, style: AppTypography.titleSmall),
                  subtitle: Text('+${c.contributions} 本周贡献'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
