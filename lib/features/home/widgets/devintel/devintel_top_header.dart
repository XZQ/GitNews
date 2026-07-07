import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/search_routing_config.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../ai_news/application/ai_news_providers.dart';
import '../../../monitor/application/monitor_providers.dart';
import '../../../project/application/project_providers.dart';
import '../../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../trending/application/trending_providers.dart';

/// 首页(桌面)顶部条 — 复用 [PageHeader] 体系。
///
/// actions 内部含一个带红点的通知按钮 + 一个脉冲点动画的"实时同步"胶囊。
/// 通知红点根据 `monitor.stats.unreadAlertCount > 0` 动态显示/隐藏。
class DevIntelTopHeader extends ConsumerWidget {
  const DevIntelTopHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      title: l10n.tr('home.title'),
      subtitle: l10n.tr('home.subtitle'),
      searchHint: l10n.tr('home.search_hint'),
      onSearchSubmitted: (v) => _openGlobalSearch(context, ref, v),
      actions: [
        _BellWithDot(),
        const _LiveSyncBadge(),
      ],
    );
  }
}

void _openGlobalSearch(BuildContext context, WidgetRef ref, String rawQuery) {
  final entries = GlobalSearchRouter.build(
    aiNewsSetter: (q) => ref.read(aiNewsSearchQueryProvider.notifier).state = q,
    techHotspotSetter: (q) =>
        ref.read(techHotspotSearchQueryProvider.notifier).state = q,
    monitorSetter: (q) =>
        ref.read(monitorSearchQueryProvider.notifier).state = q,
    projectSetter: (q) =>
        ref.read(projectSearchQueryProvider.notifier).state = q,
    trendingSetter: (q) =>
        ref.read(trendingSearchQueryProvider.notifier).state = q,
  );
  GlobalSearchRouter.route(
    rawQuery: rawQuery,
    entries: entries,
    fallbackSetter: (q) =>
        ref.read(trendingSearchQueryProvider.notifier).state = q,
    onRoute: (route) => context.go(route),
  );
}

/// 通知铃铛 — 红点根据未读告警数动态显示。
class _BellWithDot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final monitor = ref.watch(monitorDigestProvider).valueOrNull;
    final hasUnread = (monitor?.stats.unreadAlertCount ?? 0) > 0;
    return Semantics(
      label: l10n.tr('a11y.notification'),
      button: true,
      child: IconButton(
        onPressed: () => context.go('/monitor'),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            if (hasUnread)
              const Positioned(
                right: -2,
                top: -2,
                child: _Dot(),
              ),
          ],
        ),
        tooltip: l10n.tr('home.monitor_center'),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      );
}

/// 实时同步胶囊(带脉冲点)。
class _LiveSyncBadge extends StatelessWidget {
  const _LiveSyncBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeaderStatPill(
      icon: Icons.circle,
      label: l10n.tr('home.live_sync'),
      color: AppColors.success,
    );
  }
}
