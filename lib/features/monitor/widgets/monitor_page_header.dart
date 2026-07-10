import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
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
    final freshness = ref.watch(monitorFreshnessProvider).valueOrNull;
    return PageHeader(
      icon: Icons.radar_rounded,
      iconAccent: AppColors.success,
      title: l10n.tr('monitor.title'),
      subtitle: l10n.tr('monitor.subtitle'),
      searchHint: l10n.tr('monitor.search_hint'),
      searchValue: query,
      onSearchChanged: (v) => ref.read(monitorSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) => ref.read(monitorSearchQueryProvider.notifier).state = v,
      onRefresh: () => forceRefreshMonitor(ref),
      pills: [
        if (freshness != null) DataFreshnessBadge(freshness: freshness),
        HeaderStatPill(
          icon: Icons.circle,
          label: l10n.tr('monitor.unread_count').replaceAll('{n}', stats.unreadAlertCount.toString()),
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
