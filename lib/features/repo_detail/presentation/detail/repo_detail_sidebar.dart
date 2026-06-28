import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/demo_data.dart';
import 'repo_detail_helpers.dart';

class RepoDetailAboutCard extends StatelessWidget {
  const RepoDetailAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '关于',
            subtitle: 'README 摘要',
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'A modern runtime for JavaScript and TypeScript. Built on V8, Rust, and Tokio. Provides a secure, production-ready environment for building web apps.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class RepoDetailTopicsCard extends StatelessWidget {
  const RepoDetailTopicsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '话题',
            subtitle: '仓库相关技术话题',
          ),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Chip(label: Text('运行时')),
              Chip(label: Text('TypeScript')),
              Chip(label: Text('Rust')),
              Chip(label: Text('命令行')),
              Chip(label: Text('Web')),
            ],
          ),
        ],
      ),
    );
  }
}

class RepoDetailRelatedReposCard extends StatelessWidget {
  const RepoDetailRelatedReposCard({required this.repos, super.key});

  final List<DemoRepo> repos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '相关仓库',
              subtitle: '同领域的热门项目',
            ),
          ),
          for (final r in repos) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Color(r.color).withValues(alpha: 0.16),
                child: Text(
                  r.language.isNotEmpty ? r.language[0] : '?',
                  style:
                      AppTypography.labelSmall.copyWith(color: Color(r.color)),
                ),
              ),
              title: Text(r.fullName, style: AppTypography.titleSmall),
              trailing: Text(
                '+${shortNumber(r.starDelta)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 信息标签胶囊:用于相关仓库 / 话题等小标签。
class RepoPill extends StatelessWidget {
  const RepoPill({required this.text, required this.color, super.key});

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
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
