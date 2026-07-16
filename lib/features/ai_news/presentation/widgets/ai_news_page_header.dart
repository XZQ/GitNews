import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/header_search_field.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/ai_news_library_providers.dart';
import '../../application/ai_news_providers.dart';
import '../../application/ai_news_reminder_providers.dart';
import 'ai_news_library_filters_dialog.dart';

/* 
*AI 动态页顶部条 — 复用 [PageHeader] 体系。
*/
class AiNewsPageHeader extends ConsumerWidget {
  const AiNewsPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(aiNewsSearchQueryProvider);
    final freshness = ref.watch(aiNewsFreshnessProvider);
    final readLaterOnly = ref.watch(aiNewsReadLaterOnlyProvider);
    final libraryFilter = ref.watch(aiNewsLibraryFilterProvider);
    final unreadReminders = ref.watch(aiNewsUnreadReminderCountProvider);
    final actions = <Widget>[
      HeaderAction(
        icon: unreadReminders > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
        tooltip: l10n.tr('ai_news.reminders.unread').replaceAll('{count}', '$unreadReminders'),
        onPressed: () => context.go('/ai_news/reminders'),
      ),
      HeaderAction(
        icon: libraryFilter.isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
        tooltip: l10n.tr('ai_news.filters.title'),
        onPressed: () => showAiNewsLibraryFiltersDialog(context, ref),
      ),
      HeaderAction(
        icon: readLaterOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        tooltip: l10n.tr(readLaterOnly ? 'ai_news.read_later_show_all' : 'ai_news.read_later_filter'),
        onPressed: () => ref.read(aiNewsReadLaterOnlyProvider.notifier).state = !readLaterOnly,
      ),
      HeaderAction(
        icon: Icons.refresh_rounded,
        tooltip: l10n.tr('common.refresh'),
        onPressed: () => ref.invalidate(aiNewsItemsNotifierProvider),
      ),
    ];

    return PageHeader(
      title: l10n.tr('ai_news.title'),
      subtitle: l10n.tr('ai_news.subtitle'),
      searchHint: l10n.tr('ai_news.search_hint'),
      searchValue: query,
      onSearchChanged: (v) => ref.read(aiNewsSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) => ref.read(aiNewsSearchQueryProvider.notifier).state = v,
      pills: [DataFreshnessBadge(freshness: freshness)],
      actions: actions,
    );
  }
}

/*
*AI 页移动端固定标题栏。
*
*标题与高频动作始终可见;搜索框和分类导航由页面滚动区承载。
*/
class AiNewsCompactAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AiNewsCompactAppBar({super.key});

  // 设计稿对应的紧凑标题栏高度。
  static const double _toolbarHeight = 48;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final readLaterOnly = ref.watch(aiNewsReadLaterOnlyProvider);
    final libraryFilter = ref.watch(aiNewsLibraryFilterProvider);
    final unreadReminders = ref.watch(aiNewsUnreadReminderCountProvider);
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      titleSpacing: AppSpacing.lg,
      backgroundColor: colors.surface,
      title: Text(
        l10n.tr('ai_news.title'),
        style: AppTypography.headlineLarge.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800, height: 1),
      ),
      actions: [
        _CompactHeaderAction(
          icon: Icons.notifications_none_rounded,
          tooltip: l10n.tr('ai_news.reminders.unread').replaceAll('{count}', '$unreadReminders'),
          showBadge: unreadReminders > 0,
          onPressed: () => context.go('/ai_news/reminders'),
        ),
        _CompactHeaderAction(
          icon: libraryFilter.isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          tooltip: l10n.tr('ai_news.filters.title'),
          onPressed: () => showAiNewsLibraryFiltersDialog(context, ref),
        ),
        _CompactHeaderAction(
          icon: readLaterOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          tooltip: l10n.tr(readLaterOnly ? 'ai_news.read_later_show_all' : 'ai_news.read_later_filter'),
          onPressed: () => ref.read(aiNewsReadLaterOnlyProvider.notifier).state = !readLaterOnly,
        ),
        _CompactHeaderAction(
          icon: Icons.refresh_rounded,
          tooltip: l10n.tr('common.refresh'),
          onPressed: () => ref.invalidate(aiNewsItemsNotifierProvider),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/*
*AI 页移动端搜索与数据状态行。
*/
class AiNewsCompactSearchBar extends ConsumerWidget {
  const AiNewsCompactSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final query = ref.watch(aiNewsSearchQueryProvider);
    final freshness = ref.watch(aiNewsFreshnessProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: HeaderSearchField(
              hintText: l10n.tr('ai_news.search_hint'),
              value: query,
              onChanged: (value) => ref.read(aiNewsSearchQueryProvider.notifier).state = value,
              onSubmitted: (value) => ref.read(aiNewsSearchQueryProvider.notifier).state = value,
              height: 40,
              outlined: true,
              fillColor: colors.surface,
              borderRadius: AppRadius.lg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm2),
          DataFreshnessBadge(freshness: freshness, compact: false),
        ],
      ),
    );
  }
}

/*
*移动端标题栏动作:统一 40dp 热区,可选未读状态点。
*/
class _CompactHeaderAction extends StatelessWidget {
  const _CompactHeaderAction({required this.icon, required this.tooltip, required this.onPressed, this.showBadge = false});

  // 动作图标。
  final IconData icon;

  // 无障碍提示。
  final String tooltip;

  // 点击回调。
  final VoidCallback onPressed;

  // 是否显示未读状态点。
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Badge(
      isLabelVisible: showBadge,
      smallSize: 7,
      backgroundColor: colors.primary,
      offset: const Offset(-5, 5),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: colors.onSurface),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
