import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/server_connection_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/self_hosted_server_providers.dart';

class SelfHostedServerPage extends ConsumerWidget {
  const SelfHostedServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(serverConnectionControllerProvider);
    final status = ref.watch(selfHostedServerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('settings.server.title')),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: SectionHeader(
                  title: l10n.tr('settings.server.connection'),
                  subtitle: l10n.tr('settings.server.description'),
                  trailing: FilledButton.icon(
                    onPressed: status.busy ? null : () => _edit(context, ref, connection),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(l10n.tr('common.edit')),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: [
                    _ConnectionRow(
                      label: l10n.tr('settings.server.base_url'),
                      value: connection.baseUrl,
                    ),
                    _ConnectionRow(
                      label: l10n.tr('settings.server.workspace'),
                      value: connection.workspaceId,
                    ),
                    _ConnectionRow(
                      label: l10n.tr('settings.server.member'),
                      value: connection.memberId,
                    ),
                    _ConnectionRow(
                      label: l10n.tr('settings.server.api_key'),
                      value: connection.configured ? connection.maskedKey : l10n.tr('settings.server.not_configured'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: l10n.tr('settings.server.sync_title'),
                      subtitle: l10n.tr('settings.server.sync_note'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: status.busy ? null : () => ref.read(selfHostedServerControllerProvider.notifier).testConnection(),
                          icon: const Icon(Icons.health_and_safety_outlined),
                          label: Text(l10n.tr('settings.server.test')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: status.busy ? null : () => ref.read(selfHostedServerControllerProvider.notifier).pushConfig(),
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(l10n.tr('settings.server.push')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: status.busy ? null : () => ref.read(selfHostedServerControllerProvider.notifier).pullConfig(),
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: Text(l10n.tr('settings.server.pull')),
                        ),
                      ],
                    ),
                    if (status.busy) ...[
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(),
                    ],
                    if (status.messageKey != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.tr(status.messageKey!),
                        style: AppTypography.bodySmall.copyWith(
                          color: status.error ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ServerConnectionState current,
  ) async {
    final draft = await showDialog<_ServerDraft>(
      context: context,
      builder: (_) => _ServerConnectionDialog(current: current),
    );
    if (draft == null) {
      return;
    }
    try {
      await ref.read(serverConnectionControllerProvider.notifier).save(
            baseUrl: draft.baseUrl,
            workspaceId: draft.workspaceId,
            memberId: draft.memberId,
            apiKey: draft.apiKey,
          );
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).tr('settings.server.invalid'))),
        );
      }
    }
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _ServerConnectionDialog extends StatefulWidget {
  const _ServerConnectionDialog({required this.current});

  final ServerConnectionState current;

  @override
  State<_ServerConnectionDialog> createState() => _ServerConnectionDialogState();
}

class _ServerConnectionDialogState extends State<_ServerConnectionDialog> {
  late final TextEditingController _url;
  late final TextEditingController _workspace;
  late final TextEditingController _member;
  final _key = TextEditingController();

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.current.baseUrl);
    _workspace = TextEditingController(text: widget.current.workspaceId);
    _member = TextEditingController(text: widget.current.memberId);
  }

  @override
  void dispose() {
    _url.dispose();
    _workspace.dispose();
    _member.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.tr('settings.server.connection')),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _url, decoration: InputDecoration(labelText: l10n.tr('settings.server.base_url'))),
            TextField(controller: _workspace, decoration: InputDecoration(labelText: l10n.tr('settings.server.workspace'))),
            TextField(controller: _member, decoration: InputDecoration(labelText: l10n.tr('settings.server.member'))),
            TextField(
              controller: _key,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.tr('settings.server.api_key'),
                hintText: widget.current.configured ? l10n.tr('settings.server.keep_key') : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.tr('common.cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ServerDraft(
              baseUrl: _url.text,
              workspaceId: _workspace.text,
              memberId: _member.text,
              apiKey: _key.text.trim().isEmpty ? widget.current.apiKey ?? '' : _key.text,
            ),
          ),
          child: Text(l10n.tr('common.save')),
        ),
      ],
    );
  }
}

class _ServerDraft {
  const _ServerDraft({required this.baseUrl, required this.workspaceId, required this.memberId, required this.apiKey});

  final String baseUrl;
  final String workspaceId;
  final String memberId;
  final String apiKey;
}
