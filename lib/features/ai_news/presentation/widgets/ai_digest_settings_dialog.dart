import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/ai_model_providers_config.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/ai_digest_config_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/*
*AI 日报 LLM 配置对话框。
*内置 Base URL 与模型联动;自定义选项保留任意兼容端点能力。
*/
class AiDigestSettingsDialog extends ConsumerStatefulWidget {
  const AiDigestSettingsDialog({super.key});

  @override
  ConsumerState<AiDigestSettingsDialog> createState() => _AiDigestSettingsDialogState();
}

class _AiDigestSettingsDialogState extends ConsumerState<AiDigestSettingsDialog> {
  // 新 Key 输入框;已保存 Key 不回填明文。
  late final TextEditingController _keyController;

  // 自定义端点输入框。
  late final TextEditingController _customBaseUrlController;

  // 自定义模型输入框。
  late final TextEditingController _customModelController;

  // 当前服务商 ID。
  late String _providerId;

  // 当前内置模型 ID。
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiDigestConfigControllerProvider);
    final provider = AiModelProvidersConfig.findByBaseUrl(config.baseUrl);
    _providerId = provider?.id ?? AiModelProvidersConfig.customProviderId;
    _selectedModel = provider != null && provider.models.contains(config.model) ? config.model : provider?.defaultModel ?? '';
    _keyController = TextEditingController();
    _customBaseUrlController = TextEditingController(text: config.baseUrl);
    _customModelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _customBaseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(aiDigestConfigControllerProvider);
    final provider = AiModelProvidersConfig.findById(_providerId);
    return AlertDialog(
      title: Text(l10n.tr('ai_news.digest_settings')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('ai-digest-api-key'),
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.tr('ai_news.digest_api_key'),
                  hintText: config.configured ? config.maskedKey : 'sk-...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildProviderField(l10n),
              const SizedBox(height: AppSpacing.md),
              if (provider == null) ...[
                TextField(
                  key: const ValueKey('ai-digest-custom-base-url'),
                  controller: _customBaseUrlController,
                  decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_custom_base_url')),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('ai-digest-custom-model'),
                  controller: _customModelController,
                  decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_model')),
                ),
              ] else
                _buildModelField(l10n, provider),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.tr('ai_news.digest_key_note'),
                style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.tr('common.cancel'))),
        FilledButton(onPressed: _save, child: Text(l10n.tr('common.confirm'))),
      ],
    );
  }

  /*
  *构建包含 21 家内置 URL 与自定义选项的服务商下拉框。
  */
  Widget _buildProviderField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('ai-digest-provider'),
      initialValue: _providerId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_base_url')),
      items: [
        for (final provider in AiModelProvidersConfig.providers)
          DropdownMenuItem(
            value: provider.id,
            child: Text('${provider.name} — ${provider.baseUrl}', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        DropdownMenuItem(
          value: AiModelProvidersConfig.customProviderId,
          child: Text(l10n.tr('ai_news.digest_custom_provider'), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: _selectProvider,
    );
  }

  /*
  *构建与当前 Base URL 联动的模型下拉框。
  */
  Widget _buildModelField(AppLocalizations l10n, AiModelProviderConfig provider) {
    return DropdownButtonFormField<String>(
      key: ValueKey('ai-digest-model-${provider.id}'),
      initialValue: _selectedModel,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.tr('ai_news.digest_model')),
      items: [
        for (final model in provider.models) DropdownMenuItem(value: model, child: Text(model, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedModel = value);
        }
      },
    );
  }

  /*
  *切换服务商时同步切换到其默认模型。
  */
  void _selectProvider(String? value) {
    if (value == null) {
      return;
    }
    final provider = AiModelProvidersConfig.findById(value);
    setState(() {
      _providerId = value;
      if (provider != null) {
        _selectedModel = provider.defaultModel;
      }
    });
  }

  /*
  *保存凭据与当前联动后的 Base URL / 模型。
  */
  Future<void> _save() async {
    final config = ref.read(aiDigestConfigControllerProvider);
    final input = _keyController.text.trim();
    // 留空保留已有 Key,避免每次切换模型都要重输。
    final key = input.isEmpty && config.configured ? config.apiKey! : input;
    final provider = AiModelProvidersConfig.findById(_providerId);
    await ref.read(aiDigestConfigControllerProvider.notifier).save(
          apiKey: key,
          baseUrl: provider?.baseUrl ?? _customBaseUrlController.text,
          model: provider == null ? _customModelController.text : _selectedModel,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
