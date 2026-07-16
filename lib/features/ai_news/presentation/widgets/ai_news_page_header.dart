import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      actions: actions,
    );
  }
}

/*
*AI 页移动端固定标题栏:仅保留标题与搜索框。
*/
class AiNewsCompactAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AiNewsCompactAppBar({super.key});

  // 标题行高度。
  static const double _toolbarHeight = 48;

  // 搜索框区域高度。
  static const double _searchHeight = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + _searchHeight);

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
        const SizedBox(width: AppSpacing.xs),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_searchHeight),
        child: AiNewsCompactSearchBar(),
      ),
    );
  }
}

/* 移动端标题栏动作:通知、筛选与稍后读。 */
class _CompactHeaderAction extends StatelessWidget {
  const _CompactHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
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
        icon: Icon(icon, size: 25, color: colors.onSurface),
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/*
*AI 页移动端搜索框。
*/
class AiNewsCompactSearchBar extends ConsumerWidget {
  const AiNewsCompactSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final query = ref.watch(aiNewsSearchQueryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
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
    );
  }
}
