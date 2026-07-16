import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/relative_time_formatter.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_reminder_providers.dart';
import '../domain/ai_news_reminder.dart';

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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final reminder = items[index];
                  return _ReminderCard(reminder: reminder, onTap: () => _open(context, ref, reminder.itemId));
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

/*
*提醒列表条目:复用今日 AI 日报的 [AppCard] 表面规范。
*/
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.onTap});

  // 提醒实体。
  final AiNewsReminder reminder;

  // 打开对应资讯详情。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final accent = reminder.isRead ? colors.onSurfaceVariant : colors.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(reminder.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: reminder.isRead ? FontWeight.w600 : FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  '${reminder.source} · ${formatRelativeTime(l10n, reminder.publishedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!reminder.isRead) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}
