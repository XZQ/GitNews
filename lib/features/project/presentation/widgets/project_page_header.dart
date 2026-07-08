import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      onSearchChanged: (v) =>
          ref.read(projectSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) =>
          ref.read(projectSearchQueryProvider.notifier).state = v,
      onRefresh: () => ref.invalidate(projectDigestProvider),
      pills: [_NeutralPill(label: l10n.tr('project.pill.this_week'))],
      actions: [
        HeaderAction(
          icon: Icons.download_outlined,
          tooltip: l10n.tr('project.export'),
          onPressed: () => _exportReport(context, ref),
        ),
      ],
    );
  }
}

Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final digest = await ref.read(filteredProjectDigestProvider.future);
    final directory = await getApplicationDocumentsDirectory();
    final file = await writeProjectDigestMarkdown(
      digest: digest,
      outputDirectory: directory,
      generatedAt: DateTime.now(),
    );
    messenger.showSnackBar(SnackBar(content: Text('报告已导出: ${file.path}')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('报告导出失败,请稍后重试')));
  }
}

class _NeutralPill extends StatelessWidget {
  const _NeutralPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
