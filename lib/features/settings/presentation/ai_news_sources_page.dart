import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/relative_time_formatter.dart';
import '../../../core/preferences/ai_news_reminder_preferences.dart';
import '../../../core/preferences/ai_news_source_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/*
*AI 资讯源管理页。
*
*支持内置源启停、自定义 RSS/Atom 源、连续失败健康状态与恢复默认。
*/
class AiNewsSourcesPage extends ConsumerWidget {
  const AiNewsSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sourceState = ref.watch(aiNewsSourceControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('settings.ai_sources.title')),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile')),
        actions: [
          IconButton(
            tooltip: l10n.tr('settings.ai_sources.restore'),
            onPressed: () => _restoreDefaults(context, ref),
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: l10n.tr('settings.ai_sources.summary'),
                      subtitle: l10n.tr('settings.ai_sources.enabled_count').replaceAll('{enabled}', '${sourceState.enabledCount}').replaceAll('{total}', '${sourceState.entries.length}'),
                      trailing: FilledButton.icon(
                        onPressed: () => _addSource(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.tr('settings.ai_sources.add')),
                      ),
                    ),
                    if (sourceState.degradedCount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.tr('settings.ai_sources.degraded_summary').replaceAll('{count}', '${sourceState.degradedCount}'),
                        style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.tr('settings.ai_sources.reminders')),
                  subtitle: Text(
                    l10n.tr('settings.ai_sources.reminders_note'),
                  ),
                  value: ref.watch(aiNewsReminderPreferencesProvider),
                  onChanged: (value) => ref.read(aiNewsReminderPreferencesProvider.notifier).setEnabled(value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < sourceState.entries.length; index++) ...[
                _SourceCard(entry: sourceState.entries[index]),
                if (index != sourceState.entries.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSource(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<_SourceDraft>(context: context, builder: (_) => const _AddSourceDialog());
    if (draft == null || !context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(aiNewsSourceControllerProvider.notifier).addCustom(name: draft.name, feedUrl: draft.url, categoryCode: draft.categoryCode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tr('settings.ai_sources.added'))));
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.tr('settings.ai_sources.invalid')}: ${error.message}')));
      }
    }
  }

  Future<void> _restoreDefaults(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tr('settings.ai_sources.restore')),
        content: Text(l10n.tr('settings.ai_sources.restore_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.tr('common.cancel'))),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.tr('common.confirm'))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(aiNewsSourceControllerProvider.notifier).restoreDefaults();
  }
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({required this.entry});

  final AiNewsSourceEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final health = entry.health;
    final statusColor = !entry.enabled ? colors.onSurfaceVariant : (health.isDegraded ? colors.error : colors.primary);
    final statusKey = !entry.enabled ? 'settings.ai_sources.disabled' : (health.isDegraded ? 'settings.ai_sources.degraded' : 'settings.ai_sources.healthy');
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            foregroundColor: statusColor,
            child: Icon(entry.isCustom ? Icons.rss_feed_rounded : Icons.verified_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(entry.config.name, style: AppTypography.titleMedium)),
                    Text(l10n.tr(statusKey), style: AppTypography.labelMedium.copyWith(color: statusColor)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(entry.config.feedUrl, maxLines: 2, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _healthText(l10n, entry),
                  style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: entry.enabled,
            onChanged: (value) => ref.read(aiNewsSourceControllerProvider.notifier).setEnabled(entry.config.id, value),
          ),
          if (entry.isCustom)
            IconButton(
              tooltip: l10n.tr('settings.ai_sources.delete'),
              onPressed: () => ref.read(aiNewsSourceControllerProvider.notifier).removeCustom(entry.config.id),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }

  String _healthText(AppLocalizations l10n, AiNewsSourceEntry entry) {
    final health = entry.health;
    final category = l10n.tr('settings.ai_sources.category.${entry.config.categoryCode}');
    if (health.lastSuccessAt case final success?) {
      return '$category · ${l10n.tr('settings.ai_sources.last_success')} ${formatRelativeTime(l10n, success)} · '
          '${l10n.tr('settings.ai_sources.failure_count').replaceAll('{count}', '${health.consecutiveFailures}')}';
    }
    return '$category · ${l10n.tr('settings.ai_sources.never_checked')}';
  }
}

class _SourceDraft {
  const _SourceDraft({required this.name, required this.url, required this.categoryCode});

  final String name;
  final String url;
  final String categoryCode;
}

class _AddSourceDialog extends StatefulWidget {
  const _AddSourceDialog();

  @override
  State<_AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<_AddSourceDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  String _category = AiNewsSourcesConfig.supportedCategoryCodes.first;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.tr('settings.ai_sources.dialog.title')),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.tr('settings.ai_sources.dialog.name'))),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _urlController, decoration: InputDecoration(labelText: l10n.tr('settings.ai_sources.dialog.url'))),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.tr('settings.ai_sources.dialog.category')),
              items: [
                for (final code in AiNewsSourcesConfig.supportedCategoryCodes) DropdownMenuItem(value: code, child: Text(l10n.tr('settings.ai_sources.category.$code'))),
              ],
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.tr('common.cancel'))),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_SourceDraft(name: _nameController.text, url: _urlController.text, categoryCode: _category)),
          child: Text(l10n.tr('common.save')),
        ),
      ],
    );
  }
}
