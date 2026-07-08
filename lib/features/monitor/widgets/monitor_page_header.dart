import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';

/* 
*监控页顶部条。
*/
class MonitorPageHeader extends ConsumerWidget {
  const MonitorPageHeader({required this.stats, super.key});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(monitorSearchQueryProvider);
    return PageHeader(
      icon: Icons.radar_rounded,
      iconAccent: AppColors.success,
      title: '监控',
      subtitle: '实时告警与仓库动态',
      searchHint: '搜索仓库、告警、规则...',
      searchValue: query,
      onSearchChanged: (v) =>
          ref.read(monitorSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) =>
          ref.read(monitorSearchQueryProvider.notifier).state = v,
      onRefresh: () => ref.invalidate(monitorDigestProvider),
      pills: [
        HeaderStatPill(
          icon: Icons.circle,
          label: '${stats.unreadAlertCount} 未读',
          color: AppColors.success,
        ),
      ],
      actions: [
        HeaderAction(
          icon: Icons.add_circle_outline_rounded,
          tooltip: l10n.tr('a11y.add_monitor'),
          onPressed: () => context.go('/profile/monitor'),
        ),
      ],
    );
  }
}
