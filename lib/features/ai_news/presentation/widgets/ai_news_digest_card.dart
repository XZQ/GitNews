import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/ai_digest_config_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/ai_digest_providers.dart';

/*
*今日 AI 日报卡片(列表页顶部)。
*- 未配置 Key:只显示引导与「配置」入口,不发任何请求
*- 已配置:生成 / 展示当日缓存 / 明确报错,不伪造内容
*/
class AiNewsDigestCard extends ConsumerWidget {
  const AiNewsDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(aiDigestConfigControllerProvider);
    final digest = ref.watch(aiDigestNotifierProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xl, 0),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l10n.tr('ai_news.digest_title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface))),
                if (config.configured && digest.valueOrNull != null)
                  IconButton(
                    tooltip: l10n.tr('ai_news.digest_regenerate'),
                    iconSize: 18,
                    onPressed: digest.isLoading ? null : () => ref.read(aiDigestNotifierProvider.notifier).generate(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                IconButton(
                  tooltip: l10n.tr('ai_news.digest_settings'),
                  iconSize: 18,
                  onPressed: () => showDialog<void>(context: context, builder: (_) => const AiDigestSettingsDialog()),
                  icon: const Icon(Icons.settings_outlined),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _DigestBody(config: config, digest: digest)
          ],
        ),
      ),
    );
  }
}

class _DigestBody extends ConsumerWidget {
  const _DigestBody({required this.config, required this.digest});

  final AiDigestConfigState config;
  final AsyncValue<String?> digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!config.configured) {
      return Text(l10n.tr('ai_news.digest_unconfigured'), style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant));
    }
    if (digest.isLoading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Center(child: CircularProgressIndicator()));
    }
    if (digest.hasError) {
      final kind = digest.error!.asAppException().kind.name;
      return Row(
        children: [
          Expanded(child: Text('${l10n.tr('ai_news.digest_failed')} ($kind)', style: AppTypography.bodyMedium.copyWith(color: colors.error))),
          TextButton(onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(force: true), child: Text(l10n.tr('common.retry')))
        ],
      );
    }
    final text = digest.valueOrNull;
    if (text == null || text.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: Text(l10n.tr('ai_news.digest_generate')),
        ),
      );
    }
    return SelectableText(text, style: AppTypography.bodyMedium.copyWith(color: colors.onSurface, height: 1.6));
  }
}

/*
*LLM 配置对话框。Key 走 secure storage;此处不回显完整 Key,
*留空提交表示清除。
*/
class AiDigestSettingsDialog extends ConsumerStatefulWidget {
  const AiDigestSettingsDialog({super.key});

  @override
  ConsumerState<AiDigestSettingsDialog> createState() => _AiDigestSettingsDialogState();
}

class _AiDigestSettingsDialogState extends ConsumerState<AiDigestSettingsDialog> {
  late final TextEditingController _keyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiDigestConfigControllerProvider);
    _keyController = TextEditingController();
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _modelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(aiDigestConfigControllerProvider);
    return AlertDialog(
      title: Text(l10n.tr('ai_news.digest_settings')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_api_key'), hintText: config.configured ? config.maskedKey : 'sk-...'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _baseUrlController, decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_base_url'))),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _modelController, decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_model')))
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.tr('common.cancel'))), FilledButton(onPressed: _save, child: Text(l10n.tr('common.confirm')))],
    );
  }

  Future<void> _save() async {
    final config = ref.read(aiDigestConfigControllerProvider);
    final input = _keyController.text.trim();
    // 输入框留空且此前已配置:视为保留原 Key(避免每次都要重输)。
    final key = input.isEmpty && config.configured ? config.apiKey! : input;
    await ref.read(aiDigestConfigControllerProvider.notifier).save(apiKey: key, baseUrl: _baseUrlController.text, model: _modelController.text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
