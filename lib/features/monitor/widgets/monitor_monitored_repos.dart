import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_check_status.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_check_status_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorMonitoredRepos extends StatelessWidget {
  const MonitorMonitoredRepos({required this.repos, this.checks = const {}, super.key});

  final List<RepoEntity> repos;

  // 仓库检查元数据。
  final Map<String, RepoCheckStatus> checks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: SectionHeader(title: l10n.tr('monitor.monitored_repos.title'), subtitle: l10n.tr('monitor.monitored_repos.subtitle')),
            ),
          ),
          if (repos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(icon: Icons.search_off_rounded, message: l10n.tr('monitor.monitored_repos.empty')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              sliver: SliverList.separated(
                itemCount: repos.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => MonitorMonitoredRow(repo: repos[i], check: checks[repos[i].fullName]),
              ),
            ),
        ],
      ),
    );
  }
}

/*
*监控仓库条目:统一卡片下展示真实检查状态。
*/
class MonitorMonitoredRow extends StatelessWidget {
  const MonitorMonitoredRow({required this.repo, this.dense = false, this.check, super.key});

  final RepoEntity repo;

  // 紧凑密度(移动端)。
  final bool dense;

  // 独立于仓库指标的检查状态。
  final RepoCheckStatus? check;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepoTile(repo: repo, dense: dense, onTap: () => context.go('/monitor/detail/${Uri.encodeComponent(repo.fullName)}')),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: RepoCheckStatusView(check: check),
        ),
      ],
    );
  }
}
