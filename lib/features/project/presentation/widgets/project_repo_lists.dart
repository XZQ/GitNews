import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/repo_tile.dart';
import '../../../../shared/widgets/section_header.dart';

class ProjectPopularRepos extends StatelessWidget {
  const ProjectPopularRepos({super.key});

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
              title: '本周热门',
              subtitle: '按 Star 增速排序',
            ),
          ),
          for (var i = 0; i < DemoData.trending.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: DemoData.trending[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProjectRecentlyUpdated extends StatelessWidget {
  const ProjectRecentlyUpdated({super.key});

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
              title: '最近活跃',
              subtitle: '近期有更新的仓库',
            ),
          ),
          for (var i = 0; i < DemoData.recent.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: DemoData.recent[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(DemoData.recent[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
