import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/project_exporter.dart';
import '../../application/project_providers.dart';

/* 
*报告页顶部条。
*/
class ProjectPageHeader extends ConsumerWidget {
  const ProjectPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(projectSearchQueryProvider);
    return PageHeader(
      icon: Icons.insights_rounded,
      iconAccent: AppColors.warning,
      title: l10n.tr('project.title'),
      subtitle: l10n.tr('project.subtitle'),
      searchHint: l10n.tr('project.search_hint'),
      searchValue: query,
      onSearchChanged: (v) => ref.read(projectSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) => ref.read(projectSearchQueryProvider.notifier).state = v,
      onRefresh: () {
        ref.invalidate(projectDigestResultProvider);
        ref.invalidate(projectDigestProvider);
      },
      actions: [
        const _SecondaryPagesMenu(),
        HeaderAction(icon: Icons.download_outlined, tooltip: l10n.tr('project.export'), onPressed: () => _exportReport(context, ref)),
      ],
    );
  }
}

/*
 *二级页入口菜单:探索 / 活动 / 发现 / Star 增长。
 *四个页面已实现并注册路由,此前没有任何导航入口可达。
 */
class _SecondaryPagesMenu extends StatelessWidget {
  const _SecondaryPagesMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.tr('common.more'),
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onSelected: (path) => context.go(path),
      itemBuilder: (context) => [
        _item(context, '/project/explore', Icons.explore_outlined, 'project.explore.title'),
        _item(context, '/project/activity', Icons.timeline_rounded, 'project.activity.title'),
        _item(context, '/project/discover', Icons.travel_explore_outlined, 'project.discover.title'),
        _item(context, '/project/growth', Icons.show_chart_rounded, 'project.star_growth.title'),
      ],
    );
  }

  PopupMenuItem<String> _item(BuildContext context, String path, IconData icon, String titleKey) {
    return PopupMenuItem<String>(
      value: path,
      child: ListTile(leading: Icon(icon), title: Text(AppLocalizations.of(context).tr(titleKey)), contentPadding: EdgeInsets.zero),
    );
  }
}

Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final copy = ProjectReportCopy.fromLocalizations(l10n);
  final exportedMessage = l10n.tr('project.exported');
  final failedMessage = l10n.tr('project.export_failed');
  final messenger = ScaffoldMessenger.of(context);
  try {
    final digest = await ref.read(filteredProjectDigestProvider.future);
    final directory = await getApplicationDocumentsDirectory();
    final file = await writeProjectDigestMarkdown(digest: digest, outputDirectory: directory, generatedAt: DateTime.now(), copy: copy);
    messenger.showSnackBar(SnackBar(content: Text(exportedMessage.replaceAll('{path}', file.path))));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
  }
}
