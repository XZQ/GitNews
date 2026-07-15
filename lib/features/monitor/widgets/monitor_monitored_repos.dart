import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorMonitoredRepos extends StatelessWidget {
  const MonitorMonitoredRepos({required this.repos, super.key});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(title: l10n.tr('monitor.monitored_repos.title'), subtitle: l10n.tr('monitor.monitored_repos.subtitle')),
            ),
          ),
          if (repos.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: EmptyView(icon: Icons.search_off_rounded, message: l10n.tr('monitor.monitored_repos.empty')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount: repos.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => MonitorMonitoredRow(repo: repos[i]),
              ),
            )
        ],
      ),
    );
  }
}

/*
*监控仓库条目:统一的 [RepoTile] 卡片 + 尾部健康状态徽章。
*/
class MonitorMonitoredRow extends StatelessWidget {
  const MonitorMonitoredRow({required this.repo, super.key});

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RepoTile(
      repo: repo,
      trailing: _StatusPill(text: l10n.tr('monitor.monitored_repos.status_ok')),
      onTap: () => context.go('/monitor/detail/${Uri.encodeComponent(repo.fullName)}'),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
    );
  }
}
