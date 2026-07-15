import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/relative_time_formatter.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_reminder_providers.dart';

class AiNewsRemindersPage extends ConsumerWidget {
  const AiNewsRemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reminders = ref.watch(aiNewsRemindersProvider);
    final unread = ref.watch(aiNewsUnreadReminderCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('ai_news.reminders.title')),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/ai_news'),
        ),
        actions: [
          TextButton.icon(
            onPressed: unread == 0 ? null : () => ref.read(aiNewsReminderControllerProvider).markAllRead(),
            icon: const Icon(Icons.done_all_rounded),
            label: Text(l10n.tr('ai_news.reminders.mark_all_read')),
          ),
        ],
      ),
      body: reminders.when(
        data: (items) => items.isEmpty
            ? EmptyView(
                icon: Icons.notifications_none_rounded,
                message: l10n.tr('ai_news.reminders.empty'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reminder = items[index];
                  return ListTile(
                    leading: Icon(
                      reminder.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                      color: reminder.isRead ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        fontWeight: reminder.isRead ? FontWeight.normal : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${reminder.source} · ${formatRelativeTime(l10n, reminder.publishedAt)}',
                    ),
                    onTap: () => _open(context, ref, reminder.itemId),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error.asAppException(),
          onRetry: () => ref.invalidate(aiNewsRemindersProvider),
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    await ref.read(aiNewsReminderControllerProvider).markRead(itemId);
    if (context.mounted) {
      context.go('/ai_news/detail/${Uri.encodeComponent(itemId)}');
    }
  }
}
