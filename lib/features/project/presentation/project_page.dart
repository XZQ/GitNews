import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/responsive_layout.dart';
import 'widgets/project_language_distribution.dart';
import 'widgets/project_page_header.dart';
import 'widgets/project_repo_lists.dart';
import 'widgets/project_summary_metrics.dart';
import 'widgets/project_trend_overview.dart';

/// "项目 / 报告 / 探索" 三栏内容,集中在一个 Tab。
class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('project.title'))) : null,
      body: ResponsiveLayout(
        compact: (_) => const _Mobile(),
        medium: (_) => const _Desktop(),
        expanded: (_) => const _Desktop(),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        ProjectSummaryMetrics(),
        SizedBox(height: AppSpacing.lg),
        ProjectLanguageDistribution(),
        SizedBox(height: AppSpacing.lg),
        ProjectTrendOverview(),
        SizedBox(height: AppSpacing.lg),
        ProjectPopularRepos(),
        SizedBox(height: AppSpacing.lg),
        ProjectRecentlyUpdated(),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectSummaryMetrics(),
                SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 340,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: ProjectTrendOverview()),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 4, child: ProjectLanguageDistribution()),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                ProjectPopularRepos(),
                SizedBox(height: AppSpacing.lg),
                ProjectRecentlyUpdated(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
